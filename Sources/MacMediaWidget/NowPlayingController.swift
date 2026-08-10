import AppKit
import Combine

/// Estado da faixa atualmente em reprodução, publicado para a UI.
struct TrackInfo: Equatable {
    var bundleIdentifier: String?
    var title: String?
    var artist: String?
    var album: String?
    var duration: Double?      // segundos
    var elapsedTime: Double?   // segundos (no instante de `timestamp`)
    var timestamp: Date?       // momento em que `elapsedTime` foi medido
    var isPlaying: Bool = false
    var artwork: NSImage?

    var hasContent: Bool {
        title != nil || artist != nil || album != nil
    }
}

/// Lê o Now Playing do macOS pelo `mediaremote-adapter` e roteia os comandos do widget
/// para o `Player` certo.
///
/// A leitura é sempre universal: o stream do MediaRemote enxerga qualquer fonte, então
/// é ele — e só ele — que alimenta o `TrackInfo`. Já o comando **não** é universal: o
/// `Player` resolvido a partir do `bundleIdentifier` da sessão decide se o caminho é
/// MediaRemote (transporte na sessão ativa) ou AppleScript (endereçado, com seek e
/// volume por-app). Ver `docs/fase1-multiplayer.md`.
@MainActor
final class NowPlayingController: ObservableObject {
    @Published private(set) var track = TrackInfo()
    /// Posição estimada em segundos, interpolada localmente entre atualizações
    /// do stream para a barra de progresso animar suavemente.
    @Published private(set) var displayedElapsed: Double = 0

    private var streamProcess: Process?
    private var buffer = Data()
    private var progressTimer: Timer?

    // MARK: - Estimativa de posição
    //
    // O Amazon Music não popula `elapsedTime` no Now Playing info: o stream só
    // traz `timestamp` (instante em que a faixa atual começou), `duration` e
    // `playing`. Mantemos então um cronômetro local ancorado nesse timestamp,
    // que só avança enquanto há reprodução e congela na pausa. `timestamp` semeia
    // a posição quando uma faixa nova entra ou quando o widget abre no meio dela.

    /// Posição (segundos) na âncora `anchorWall`.
    private var anchorElapsed: Double = 0
    /// Instante de parede correspondente a `anchorElapsed`.
    private var anchorWall = Date()
    /// Último `timestamp` recebido do stream, para detectar troca de faixa.
    private var lastTimestamp: Date?

    /// Quando a fonte sabe dizer a posição real (`.realPosition`), o cronômetro local
    /// deixa de ser um chute e passa a ser só interpolação entre leituras verdadeiras.
    private var lastPositionPoll = Date.distantPast
    /// Polling é subprocesso: não roda com o widget escondido, onde ninguém veria.
    var isWidgetVisible = true

    private static let isoFormatter = ISO8601DateFormatter()

    // MARK: - Players

    /// Player que controla a sessão de Now Playing atual, se houver alguma.
    var activePlayer: Player? {
        PlayerRegistry.shared.player(for: track.bundleIdentifier)
    }

    /// Player escolhido pelo usuário como preferido — o que o widget abre no play
    /// quando não há nada tocando, e o único que ele controla no modo fixo.
    var preferredPlayer: Player {
        PlayerRegistry.shared.player(for: AppSettings.shared.preferredPlayerBundleId)
            ?? AmazonMusicPlayer()
    }

    /// O player que o widget considera "seu" agora, conforme o modo de controle.
    var controlledPlayer: Player {
        switch AppSettings.shared.controlMode {
        case .automatic: return activePlayer ?? preferredPlayer
        case .fixed: return preferredPlayer
        }
    }

    /// A sessão de Now Playing pertence ao player controlado?
    var isControlledPlayerActive: Bool {
        guard let id = track.bundleIdentifier else { return false }
        return id == controlledPlayer.bundleIdentifier
    }

    /// Faixa a exibir no card.
    ///
    /// No modo fixo, quando o player escolhido não é a sessão ativa, o widget mostraria
    /// a faixa de **outro** app enquanto controla o escolhido — incoerente. Nesse caso
    /// exibe vazio: se o player escolhido não é a sessão, é porque ele não está tocando.
    var displayedTrack: TrackInfo {
        if AppSettings.shared.controlMode == .fixed, !isControlledPlayerActive {
            return TrackInfo()
        }
        return track
    }

    /// Se next/previous/seek têm onde atuar.
    ///
    /// Sem a sessão ativa, só um player com `.directedControl` (isto é, com AppleScript)
    /// consegue receber o comando. Para os outros, mandar assim seria mandar para quem
    /// estiver tocando — o vazamento de comando global de `DECISOES.md · 2026-08-05 · #01`.
    var canControlTransport: Bool {
        if isControlledPlayerActive { return true }
        return controlledPlayer.capabilities.contains(.directedControl) && controlledPlayer.isRunning
    }

    /// Por que o transporte está indisponível, para a UI mostrar em vez de só apagar
    /// os botões.
    var transportUnavailableReason: String? {
        guard !canControlTransport else { return nil }
        let name = controlledPlayer.displayName
        if !controlledPlayer.isInstalled { return "\(name) não está instalado" }
        if !controlledPlayer.isRunning { return "\(name) está fechado" }
        return "\(name) não está tocando"
    }

    // MARK: - Stream

    func start() {
        guard streamProcess == nil else { return }

        let process = MediaRemoteAdapter.makeStreamProcess()
        guard let stdout = process.standardOutput as? Pipe else { return }

        stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            Task { @MainActor in
                self?.ingest(chunk)
            }
        }

        do {
            try process.run()
            streamProcess = process
        } catch {
            NSLog("MacMediaWidget: falha ao iniciar o stream do adapter: \(error)")
        }

        startProgressTimer()
    }

    func stop() {
        progressTimer?.invalidate()
        progressTimer = nil
        streamProcess?.terminate()
        streamProcess = nil
    }

    /// Recalcula a posição estimada a cada 0,5s enquanto há reprodução.
    private func startProgressTimer() {
        progressTimer?.invalidate()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshDisplayedElapsed() }
        }
        RunLoop.main.add(timer, forMode: .common)
        progressTimer = timer
    }

    private func refreshDisplayedElapsed() {
        displayedElapsed = estimatedElapsed(at: Date(), playing: track.isPlaying)
        pollRealPositionIfNeeded()
    }

    /// Nas fontes que expõem posição real, relê 1×/s e **reancora** o cronômetro local
    /// com o valor verdadeiro. Assim a barra continua andando suave a 2 Hz sem custar
    /// dois subprocessos por segundo, e um seek feito dentro do player aparece no
    /// widget em até um segundo — o que no Amazon Music é impossível
    /// (`DECISOES.md · 2026-08-05 · #01`).
    private func pollRealPositionIfNeeded() {
        guard isWidgetVisible,
              let player = activePlayer,
              player.capabilities.contains(.realPosition)
        else { return }

        let now = Date()
        guard now.timeIntervalSince(lastPositionPoll) >= 1 else { return }
        lastPositionPoll = now

        Task { [weak self] in
            guard let value = await player.position() else { return }
            guard let self else { return }
            self.anchorElapsed = value
            self.anchorWall = Date()
            self.displayedElapsed = self.estimatedElapsed(at: Date(), playing: self.track.isPlaying)
        }
    }

    /// Posição estimada num instante, dado o estado de reprodução: parte da âncora
    /// e soma o tempo de parede decorrido apenas se estava tocando.
    ///
    /// `clamped` limita o resultado à duração da faixa, o que é o certo para
    /// exibir mas errado para gravar de volta na âncora: uma âncora clampada
    /// fica presa no fim da faixa e a barra nunca mais anda.
    private func estimatedElapsed(at now: Date, playing: Bool, clamped: Bool = true) -> Double {
        var value = anchorElapsed
        if playing { value += now.timeIntervalSince(anchorWall) }
        if clamped, let dur = track.duration { value = min(value, dur) }
        return max(value, 0)
    }

    /// Acumula bytes do stdout e processa linha a linha (cada linha = 1 JSON).
    private func ingest(_ chunk: Data) {
        buffer.append(chunk)
        let newline = UInt8(ascii: "\n")
        while let idx = buffer.firstIndex(of: newline) {
            let lineData = buffer[buffer.startIndex..<idx]
            buffer.removeSubrange(buffer.startIndex...idx)
            if !lineData.isEmpty {
                handleLine(Data(lineData))
            }
        }
    }

    private func handleLine(_ data: Data) {
        guard
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let payload = obj["payload"] as? [String: Any]
        else { return }

        // `diff: false` é um snapshot completo do Now Playing. Um snapshot SEM
        // faixa alguma significa que não existe mais sessão — o app de música foi
        // encerrado. Nesse caso é preciso zerar o estado: mesclar (o que o código
        // fazia sempre, por ignorar o campo `diff`) deixava o `bundleIdentifier`
        // antigo grudado, e o play do widget virava um `togglePlayPause` global,
        // que o macOS entrega ao Music.app da Apple — abrindo o app errado.
        let isSnapshot = (obj["diff"] as? Bool) == false
        if isSnapshot, payload["bundleIdentifier"] == nil, payload["title"] == nil {
            track = TrackInfo()
            lastTimestamp = nil
            anchorElapsed = 0
            anchorWall = Date()
            refreshDisplayedElapsed()
            return
        }

        // O stream vem como diff por padrão: só campos alterados estão presentes.
        // Mesclamos sobre o estado atual.
        var t = track

        if let v = payload["bundleIdentifier"] as? String { t.bundleIdentifier = v }
        if let v = payload["title"] as? String { t.title = v }
        if let v = payload["artist"] as? String { t.artist = v }
        if let v = payload["album"] as? String { t.album = v }
        if let v = payload["duration"] as? Double { t.duration = v }
        if let v = payload["elapsedTime"] as? Double {
            t.elapsedTime = v
            t.timestamp = Date()
        }
        if let v = payload["playing"] as? Bool { t.isPlaying = v }

        if let b64 = payload["artworkData"] as? String,
           let imgData = Data(base64Encoded: b64),
           let image = NSImage(data: imgData) {
            t.artwork = image
        }

        // Reancora o cronômetro local antes de adotar o novo estado.
        let now = Date()
        if let tsString = payload["timestamp"] as? String,
           let ts = Self.isoFormatter.date(from: tsString),
           ts != lastTimestamp {
            // Faixa nova: o timestamp marca o início dela, então a posição atual é
            // o tempo de parede decorrido desde ele.
            //
            // Só que o Amazon Music não reemite o timestamp ao pausar: numa faixa
            // parada há horas, esse cálculo dá um valor absurdo. Nesse caso a
            // posição real é desconhecida e mostrar do início é melhor do que
            // travar a barra cheia — que era o que acontecia, porque a âncora
            // acabava fixada na duração e não saía mais de lá até trocar de faixa.
            lastTimestamp = ts
            let sinceStart = max(0, now.timeIntervalSince(ts))
            if let dur = t.duration ?? track.duration, sinceStart > dur {
                anchorElapsed = 0
            } else {
                anchorElapsed = sinceStart
            }
            anchorWall = now
        } else if payload["playing"] != nil, t.isPlaying != track.isPlaying {
            // Transição play/pause sem novo timestamp: consolida o acumulado com o
            // estado ANTIGO para congelar (ou retomar) na posição correta. Sem
            // clamp, para não fixar a âncora no fim da faixa.
            anchorElapsed = estimatedElapsed(at: now, playing: track.isPlaying, clamped: false)
            anchorWall = now
        }

        track = t
        refreshDisplayedElapsed()
    }

    // MARK: - Comandos

    func next() {
        guard canControlTransport else { return }
        controlledPlayer.next()
    }

    func previous() {
        guard canControlTransport else { return }
        controlledPlayer.previous()
    }

    /// Move a posição da faixa. Só age onde a capacidade existe — no Amazon Music o
    /// comando seria aceito e ignorado, e a barra andaria mentindo.
    func seek(to seconds: Double) {
        guard canControlTransport else { return }
        let player = controlledPlayer
        guard player.capabilities.contains(.seek) else { return }
        player.seek(to: seconds)
        // Reancora na hora: esperar o próximo poll deixaria a barra pular de volta
        // por até um segundo depois de o usuário soltar o dedo.
        anchorElapsed = seconds
        anchorWall = Date()
        lastPositionPoll = Date()
        refreshDisplayedElapsed()
    }

    /// Aciona play/pause a partir do botão central do widget.
    ///
    /// É o único comando que pode **abrir** um app: quando não há sessão onde atuar,
    /// o widget assume o player controlado em vez de mandar um comando global às
    /// cegas — que o macOS entregaria ao player padrão do sistema, abrindo o app
    /// errado (`DECISOES.md · 2026-08-05 · #01`).
    func playPause() {
        let target = controlledPlayer

        // Caminho normal: o alvo é a sessão de Now Playing e está mesmo vivo. A
        // checagem do processo é rede de segurança — `togglePlayPause` é global.
        if isControlledPlayerActive, target.isRunning {
            target.playPause()
            return
        }

        // Alvo endereçável por AppleScript: o comando chega nele mesmo com outro app
        // ocupando a sessão de Now Playing. É o que faz o modo fixo valer a pena.
        if target.capabilities.contains(.directedControl), target.isRunning {
            target.playPause()
            return
        }

        // Sobrou o caso sem sessão utilizável: abre o alvo e só manda o play quando
        // ele virar a sessão.
        guard AppSettings.shared.autoLaunchOnPlay else { return }
        // App não instalado: `launch()` já avisou o usuário; não adianta esperar
        // por uma sessão de Now Playing que nunca vai existir.
        guard target.launch() else { return }
        waitForSessionThenPlay(target)
    }

    /// Após abrir o player, aguarda ele virar a sessão de Now Playing antes de mandar
    /// o play. Um `play` global enviado cedo demais vaza para o app de música padrão
    /// do sistema (Music.app da Apple), que então abre indevidamente. Só dispara o
    /// comando quando o Now Playing já é o player esperado; se não virar dentro do
    /// tempo, desiste sem enviar nada.
    private func waitForSessionThenPlay(_ player: Player, attempt: Int = 0) {
        let maxAttempts = 30 // ~15s (0,5s por tentativa)
        if track.bundleIdentifier == player.bundleIdentifier {
            if !track.isPlaying { player.play() }
            return
        }
        guard attempt < maxAttempts else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.waitForSessionThenPlay(player, attempt: attempt + 1)
        }
    }
}
