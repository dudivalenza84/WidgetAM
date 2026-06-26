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

/// IDs de comando do MediaRemote (MRCommand). Repassados ao adapter via `send`.
enum MediaCommand: Int {
    case play = 0
    case pause = 1
    case togglePlayPause = 2
    case nextTrack = 4
    case previousTrack = 5
}

/// Faz a ponte com o app oficial `Amazon Music.app` (ou qualquer fonte do Now
/// Playing) através do `mediaremote-adapter`: roda o `mediaremote-adapter.pl`
/// via `/usr/bin/perl` (entitled) como subprocesso, lê o stream JSON e envia
/// comandos de transporte pelo mesmo mecanismo.
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

    private static let isoFormatter = ISO8601DateFormatter()

    // MARK: - Caminhos dos recursos bundlados

    private static let perlPath = "/usr/bin/perl"

    /// Diretório `mediaremote-adapter/` dentro de Resources do bundle.
    /// Em desenvolvimento (rodando o binário SPM solto), cai no Cellar do brew.
    private static func adapterDir() -> String {
        if let resource = Bundle.main.resourcePath {
            let bundled = resource + "/mediaremote-adapter"
            if FileManager.default.fileExists(atPath: bundled + "/mediaremote-adapter.pl") {
                return bundled
            }
        }
        // Fallback de desenvolvimento.
        return "/opt/homebrew/Cellar/media-control/0.7.6/lib/media-control"
    }

    private static func frameworkPath() -> String {
        if let resource = Bundle.main.resourcePath {
            let bundled = resource + "/mediaremote-adapter/MediaRemoteAdapter.framework"
            if FileManager.default.fileExists(atPath: bundled) {
                return bundled
            }
        }
        return "/opt/homebrew/Cellar/media-control/0.7.6/Frameworks/MediaRemoteAdapter.framework"
    }

    private static func scriptPath() -> String {
        adapterDir() + "/mediaremote-adapter.pl"
    }

    // MARK: - Stream

    func start() {
        guard streamProcess == nil else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.perlPath)
        process.arguments = [Self.scriptPath(), Self.frameworkPath(), "stream"]

        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = Pipe()

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
    }

    /// Posição estimada num instante, dado o estado de reprodução: parte da âncora
    /// e soma o tempo de parede decorrido apenas se estava tocando.
    private func estimatedElapsed(at now: Date, playing: Bool) -> Double {
        var value = anchorElapsed
        if playing { value += now.timeIntervalSince(anchorWall) }
        if let dur = track.duration { value = min(value, dur) }
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
            // Faixa nova ou reposicionada: o timestamp marca o início; estimamos a
            // posição atual pelo tempo de parede decorrido desde ele.
            lastTimestamp = ts
            anchorElapsed = max(0, now.timeIntervalSince(ts))
            anchorWall = now
        } else if payload["playing"] != nil, t.isPlaying != track.isPlaying {
            // Transição play/pause sem novo timestamp: consolida o acumulado com o
            // estado ANTIGO para congelar (ou retomar) na posição correta.
            anchorElapsed = estimatedElapsed(at: now, playing: track.isPlaying)
            anchorWall = now
        }

        track = t
        refreshDisplayedElapsed()
    }

    // MARK: - Comandos

    func send(_ command: MediaCommand) {
        runAdapter(["send", String(command.rawValue)])
    }

    /// Aciona play/pause a partir do botão central do widget. Se a preferência
    /// `autoLaunchOnPlay` estiver ligada, está pausado e o `Amazon Music.app` não
    /// estiver rodando, abre o app antes de mandar o play — caso contrário o
    /// comando não teria sessão de Now Playing onde atuar.
    func playPauseEnsuringApp() {
        // Se o Now Playing atual já é o Amazon Music, alterna normalmente — o
        // comando tem uma sessão concreta onde atuar.
        if track.bundleIdentifier == Self.amazonMusicBundleId {
            send(.togglePlayPause)
            return
        }

        // Sessão ainda não é o Amazon Music (app fechado, ou aberto mas sem nada
        // tocando). Um `togglePlayPause` global aqui vazaria para o player padrão
        // do sistema (Music.app da Apple), que abriria indevidamente. Em vez
        // disso, garante o Amazon Music e só manda o play quando ele virar a
        // sessão de Now Playing.
        guard AppSettings.shared.autoLaunchOnPlay else { return }
        if !Self.isAmazonMusicRunning() {
            // App não instalado: openAmazonMusic já avisou o usuário; não adianta
            // esperar pela sessão de Now Playing que nunca vai existir.
            guard Self.openAmazonMusic() else { return }
        }
        waitForAmazonMusicThenPlay()
    }

    /// Após abrir o Amazon Music, aguarda ele virar a sessão de Now Playing antes
    /// de mandar o play. Um `play` global enviado cedo demais vaza para o app de
    /// música padrão do sistema (Music.app da Apple), que então abre indevidamente.
    /// Só dispara o comando quando o Now Playing já é o Amazon Music; se não virar
    /// dentro do tempo, desiste sem enviar nada.
    private func waitForAmazonMusicThenPlay(attempt: Int = 0) {
        let maxAttempts = 30 // ~15s (0,5s por tentativa)
        if track.bundleIdentifier == Self.amazonMusicBundleId {
            if !track.isPlaying { send(.play) }
            return
        }
        guard attempt < maxAttempts else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.waitForAmazonMusicThenPlay(attempt: attempt + 1)
        }
    }

    /// Seek para uma posição absoluta em segundos.
    func seek(toSeconds seconds: Double) {
        let micros = Int(seconds * 1_000_000)
        runAdapter(["seek", String(micros)])
    }

    /// Executa o adapter de forma efêmera (comandos one-shot) e ignora a saída.
    private func runAdapter(_ extraArgs: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.perlPath)
        process.arguments = [Self.scriptPath(), Self.frameworkPath()] + extraArgs
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            NSLog("MacMediaWidget: falha ao enviar comando ao adapter: \(error)")
        }
    }

    // MARK: - Util

    static let amazonMusicBundleId = "com.amazon.music"

    /// Indica se o `Amazon Music.app` está em execução no momento.
    static func isAmazonMusicRunning() -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: amazonMusicBundleId).isEmpty
    }

    /// URL oficial de download do Amazon Music para desktop.
    static let amazonMusicDownloadURL = URL(string: "https://am.app.link/zb0Bk69BNub/?__branch_flow_type=qr_code")!

    /// Abre (ou traz à frente) o app oficial do Amazon Music. Se o app não estiver
    /// instalado, avisa o usuário, oferece abrir a página oficial de instalação e
    /// retorna `false`. Retorna `true` quando o app existe e o launch foi disparado.
    @discardableResult
    static func openAmazonMusic() -> Bool {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: amazonMusicBundleId) else {
            NSLog("MacMediaWidget: Amazon Music.app não encontrado (\(amazonMusicBundleId))")
            promptInstallAmazonMusic()
            return false
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config)
        return true
    }

    /// Mostra um alerta informando que o Amazon Music não está instalado e oferece
    /// abrir a página oficial de download no navegador.
    static func promptInstallAmazonMusic() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Amazon Music não está instalado"
            alert.informativeText = "O widget controla o app oficial do Amazon Music, que não foi encontrado neste Mac. Deseja abrir a página de instalação?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Abrir instalação")
            alert.addButton(withTitle: "Cancelar")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(amazonMusicDownloadURL)
            }
        }
    }
}
