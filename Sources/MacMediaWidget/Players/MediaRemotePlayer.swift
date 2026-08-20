import AppKit

/// Player genérico, que fala com a fonte apenas pelo MediaRemote.
///
/// É o denominador comum: serve para qualquer app — inclusive um que este código não
/// conheça — porque não depende de AppleScript nem de nada específico. Em troca, só
/// oferece transporte, e só enquanto a fonte for a sessão de Now Playing do sistema
/// (sem `.directedControl`).
@MainActor
class MediaRemotePlayer: Player {
    let bundleIdentifier: String
    private let fixedDisplayName: String?

    init(bundleIdentifier: String, displayName: String? = nil) {
        self.bundleIdentifier = bundleIdentifier
        self.fixedDisplayName = displayName
    }

    var displayName: String {
        fixedDisplayName
            ?? Self.localizedName(forBundleIdentifier: bundleIdentifier)
            ?? bundleIdentifier
    }

    var capabilities: PlayerCapabilities { .fullTransport }

    /// Declaradas aqui, e não só como default do protocolo, para que subclasses possam
    /// sobrescrevê-las: implementação em extension de protocolo é despachada
    /// estaticamente e `override` não a alcançaria.
    var installURL: URL? { nil }
    var catalogID: String { bundleIdentifier }

    func playPause() { MediaRemoteAdapter.send(.togglePlayPause) }
    func play() { MediaRemoteAdapter.send(.play) }
    func next() { MediaRemoteAdapter.send(.nextTrack) }
    func previous() { MediaRemoteAdapter.send(.previousTrack) }

    /// O adapter aceita posicionamento, e em alguns apps ele **funciona de verdade**
    /// (TIDAL e navegador, medidos por observação — não pelo código de retorno, que o
    /// Amazon Music devolve alegremente sem fazer nada). Quem chama já consultou
    /// `.seek`, então mandar aqui é seguro: nos apps sem a capacidade este método
    /// nunca é alcançado.
    ///
    /// Vale só quando o player **é** a sessão de Now Playing: o comando do MediaRemote
    /// não tem destinatário. `NowPlayingController.canControlTransport` garante isso
    /// antes de chegar aqui.
    func seek(to seconds: Double) {
        MediaRemoteAdapter.seek(to: seconds)
    }

    // Os três abaixo são no-op aqui — o MediaRemote não dá posição nem volume — mas
    // precisam existir na classe, e não apenas como default do protocolo, para que as
    // subclasses com AppleScript consigam sobrescrevê-los. Implementação em extension
    // de protocolo é despachada estaticamente.
    func position() async -> Double? { nil }
    func volume() async -> Double? { nil }
    func setVolume(_ value: Double) {}

    /// Declarado aqui pelo mesmo motivo dos anteriores: `launch()` mora numa extension
    /// de `Player`, despachada estaticamente, e o `BrowserPlayer` precisa sobrescrevê-lo
    /// para abrir a URL do serviço quando não há app instalado.
    @discardableResult
    func launch() -> Bool {
        guard !DebugFlags.simulatesMissingApp, let url = applicationURL else {
            NSLog("MacMediaWidget: \(displayName) não encontrado (\(bundleIdentifier))")
            promptInstall()
            return false
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config)
        return true
    }
}
