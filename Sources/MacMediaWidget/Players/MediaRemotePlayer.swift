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

    var capabilities: PlayerCapabilities { [.transport] }

    /// Declarada aqui, e não só como default do protocolo, para que subclasses possam
    /// sobrescrevê-la: implementação em extension de protocolo é despachada
    /// estaticamente e `override` não a alcançaria.
    var installURL: URL? { nil }

    func playPause() { MediaRemoteAdapter.send(.togglePlayPause) }
    func play() { MediaRemoteAdapter.send(.play) }
    func next() { MediaRemoteAdapter.send(.nextTrack) }
    func previous() { MediaRemoteAdapter.send(.previousTrack) }

    // Os quatro abaixo são no-op aqui — o MediaRemote não dá posição nem volume — mas
    // precisam existir na classe, e não apenas como default do protocolo, para que as
    // subclasses com AppleScript consigam sobrescrevê-los. Implementação em extension
    // de protocolo é despachada estaticamente.
    func seek(to seconds: Double) {}
    func position() async -> Double? { nil }
    func volume() async -> Double? { nil }
    func setVolume(_ value: Double) {}
}
