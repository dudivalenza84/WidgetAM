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

/// Situação do canal de leitura do Now Playing.
///
/// O widget inteiro depende de um subprocesso perl falando com um framework privado da
/// Apple. Quando isso para de funcionar — o processo morre, ou um update do macOS fecha
/// o acesso ao MediaRemote — o sintoma para o usuário é um card eternamente vazio, que
/// se confunde com "não estou ouvindo nada". Este estado existe para que o app saiba a
/// diferença e possa dizê-la.
enum AdapterHealth: Equatable {
    case starting
    case healthy
    /// O stream caiu e está sendo reaberto. `attempt` conta as tentativas seguidas.
    case reconnecting(attempt: Int)
    /// O mecanismo não está disponível nesta máquina/versão de macOS. Não adianta
    /// reconectar: é quebra estrutural, e o usuário precisa saber que o app está cego.
    case unavailable(String)

    var isHealthy: Bool { self == .healthy || self == .starting }
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

    /// Estado do canal de leitura, para a UI poder avisar em vez de fingir normalidade.
    @Published private(set) var health: AdapterHealth = .starting

    private var streamProcess: Process?
    private var buffer = Data()
    private var progressTimer: Timer?

    /// Distingue o encerramento pedido por nós (`stop()`) da morte inesperada do
    /// subprocesso — sem isso, sair do app dispararia uma tentativa de reconexão.
    private var isStopping = false
    private var reconnectAttempt = 0

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
        if !controlledPlayer.isInstalled { return L10n.playerNotInstalled(name) }
        if !controlledPlayer.isRunning { return L10n.playerNotRunning(name) }
        return L10n.playerNotPlaying(name)
    }

    // MARK: - Stream

    func start() {
        isStopping = false
        startProgressTimer()

        // A checagem de entitlement é um subprocesso curto; fora da main thread para
        // não segurar a abertura do widget.
        Task.detached {
            let entitled = MediaRemoteAdapter.isEntitled()
            await MainActor.run {
                guard !entitled else {
                    self.openStream()
                    return
                }
                self.health = .unavailable(L10n.mechanismUnavailable)
                NSLog("MacMediaWidget: adapter sem entitlement do MediaRemote — leitura indisponível")
            }
        }
    }

    func stop() {
        isStopping = true
        progressTimer?.invalidate()
        progressTimer = nil
        streamProcess?.terminate()
        streamProcess = nil
    }

    private func openStream() {
        guard streamProcess == nil, !isStopping else { return }

        let process = MediaRemoteAdapter.makeStreamProcess()
        guard let stdout = process.standardOutput as? Pipe else { return }

        stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            Task { @MainActor in
                self?.ingest(chunk)
            }
        }

        // O perl morrer é o modo de falha esperado, não o excepcional: qualquer coisa
        // que o mate (crash, mudança de sessão, atualização do brew em desenvolvimento)
        // deixaria o widget congelado na última faixa para sempre.
        process.terminationHandler = { [weak self] _ in
            Task { @MainActor in self?.handleStreamTermination() }
        }

        do {
            try process.run()
            streamProcess = process
        } catch {
            NSLog("MacMediaWidget: falha ao iniciar o stream do adapter: \(error)")
            handleStreamTermination()
        }
    }

    private func handleStreamTermination() {
        streamProcess = nil
        guard !isStopping else { return }

        reconnectAttempt += 1
        health = .reconnecting(attempt: reconnectAttempt)

        // Backoff exponencial com teto de 30s: se a causa for permanente, não faz
        // sentido gastar um subprocesso por segundo pelo resto da sessão.
        let delay = min(30, pow(2, Double(min(reconnectAttempt, 5))))
        NSLog("MacMediaWidget: stream do adapter caiu; reabrindo em \(Int(delay))s (tentativa \(reconnectAttempt))")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.openStream()
        }
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

    /// Teto do acumulador de linha. Uma linha real é grande — a capa vem como base64 no
    /// mesmo JSON, o que dá centenas de KB —, mas não ilimitada. Sem teto, um stream que
    /// despeje bytes sem nunca mandar `\n` (adapter em pânico, saída corrompida) faria o
    /// buffer crescer até consumir a memória da máquina.
    private static let maxBufferBytes = 8 * 1024 * 1024

    /// Acumula bytes do stdout e processa linha a linha (cada linha = 1 JSON).
    private func ingest(_ chunk: Data) {
        buffer.append(chunk)

        if buffer.count > Self.maxBufferBytes {
            NSLog("MacMediaWidget: linha do adapter passou de \(Self.maxBufferBytes) bytes sem terminar; descartando")
            buffer.removeAll(keepingCapacity: false)
            return
        }

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
        // Linha válida chegando é a prova de que o canal está de pé.
        if health != .healthy {
            health = .healthy
            reconnectAttempt = 0
        }

        switch NowPlayingParser.parse(data, mergingInto: track, lastTimestamp: lastTimestamp) {
        case .ignored:
            return

        case .reset:
            track = TrackInfo()
            lastTimestamp = nil
            anchorElapsed = 0
            anchorWall = Date()
            refreshDisplayedElapsed()

        case .update(let t, let newTimestamp):
            // Reancora o cronômetro local antes de adotar o novo estado.
            let now = Date()
            if let ts = newTimestamp {
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
            } else if t.isPlaying != track.isPlaying {
                // Transição play/pause sem novo timestamp: consolida o acumulado com o
                // estado ANTIGO para congelar (ou retomar) na posição correta. Sem
                // clamp, para não fixar a âncora no fim da faixa.
                anchorElapsed = estimatedElapsed(at: now, playing: track.isPlaying, clamped: false)
                anchorWall = now
            }

            track = t
            refreshDisplayedElapsed()
        }
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
