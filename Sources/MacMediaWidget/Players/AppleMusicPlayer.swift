import AppKit

/// `Music.app` da Apple — o player mais capaz da lista, e o oposto do Amazon Music.
///
/// O `.sdef` (`/System/Applications/Music.app/Contents/Resources/com.apple.Music.sdef`)
/// expõe `player position` **gravável**, `sound volume` 0–100, `mute`,
/// `shuffle enabled`, `song repeat` e os comandos de transporte. É com ele que a camada
/// AppleScript se prova, sem depender de nenhuma instalação extra.
@MainActor
final class AppleMusicPlayer: AppleScriptPlayer {
    nonisolated static let bundleID = "com.apple.Music"

    init() {
        super.init(
            bundleIdentifier: Self.bundleID,
            displayName: "Apple Music",
            // O app se chama "Music" no dicionário AppleScript, não "Apple Music".
            scriptingName: "Music"
        )
    }

    override var scriptedCapabilities: PlayerCapabilities {
        [.realPosition, .seek, .appVolume, .shuffleRepeat, .directedControl]
    }

    /// Publica `elapsedTime` no stream, então a barra fica certa mesmo se o usuário
    /// negar a Automação e todo o resto cair.
    override var unscriptedCapabilities: PlayerCapabilities { [.fullTransport, .streamPosition] }

    // MARK: - Transporte
    //
    // Vai por AppleScript, e não pelo MediaRemote, porque é endereçado: funciona mesmo
    // quando outro app é a sessão de Now Playing. É o que dá sentido ao modo fixo.

    override func playPause() { fireIfRunning("playpause") }

    /// O único comando que pode abrir o app: é o play do widget assumindo o player.
    override func play() { fire("play") }

    override func next() { fireIfRunning("next track") }

    /// `previous track` vai para a faixa anterior; `back track` voltaria ao início da
    /// atual. O botão do widget é "anterior", então é `previous track`.
    override func previous() { fireIfRunning("previous track") }

    // MARK: - Posição

    override func position() async -> Double? {
        guard isRunning else { return nil }
        return AppleScriptRunner.number(from: await tell("get player position"))
    }

    override func seek(to seconds: Double) {
        fireIfRunning("set player position to \(Int(seconds.rounded()))")
    }

    // MARK: - Volume por-app

    override func volume() async -> Double? {
        guard isRunning else { return nil }
        guard let level = AppleScriptRunner.number(from: await tell("get sound volume")) else {
            return nil
        }
        return level / 100
    }

    override func setVolume(_ value: Double) {
        let level = Int((min(max(value, 0), 1) * 100).rounded())
        fireIfRunning("set sound volume to \(level)")
    }
}
