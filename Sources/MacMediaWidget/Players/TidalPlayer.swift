import AppKit

/// `TIDAL.app` — Electron, sem dicionário AppleScript (`NSAppleScriptEnabled` ausente,
/// nenhum `.sdef`). Sobra o que o MediaRemote dá sobre a sessão ativa.
///
/// Duas diferenças práticas em relação ao Amazon Music, ambas medidas
/// (`docs/compatibilidade-players.md`): o TIDAL **obedece ao seek** do MediaRemote — a
/// faixa de 30 s posicionada em 25,99 s terminou 5 segundos depois, não 30 — e
/// **publica `elapsedTime`** no stream. O `elapsedTime` não é relógio: é uma âncora
/// reemitida a cada faixa e a cada seek, que o `NowPlayingController` usa como ponto de
/// partida e continua estimando por tempo de parede.
@MainActor
final class TidalPlayer: MediaRemotePlayer {
    nonisolated static let bundleID = "com.tidal.desktop"

    nonisolated static let installURL: URL? = URL(string: "https://tidal.com/download")

    init() {
        super.init(bundleIdentifier: Self.bundleID, displayName: "TIDAL")
    }

    override var capabilities: PlayerCapabilities { [.fullTransport, .seek] }

    override var installURL: URL? { Self.installURL }
}
