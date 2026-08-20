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

    /// O que sobrevive à Automação negada: publica `elapsedTime` no stream e obedece ao
    /// seek do MediaRemote (pedido 209,1 s → `elapsedTime=209.062`), então barra correta
    /// e barra arrastável continuam de pé mesmo sem permissão nenhuma.
    override var unscriptedCapabilities: PlayerCapabilities {
        [.fullTransport, .streamPosition, .seek]
    }
}
