import AppKit

/// `Deezer.app` — Electron, sem dicionário AppleScript, como o TIDAL. O que ele tem de
/// diferente está todo no que **não** funciona.
///
/// Medido em `docs/compatibilidade-players.md`:
/// - **`previous` não tem efeito.** Não troca de faixa nem reinicia a atual: com a
///   faixa em 42,8 s o comando passou em branco e o tempo seguiu correndo. Por isso a
///   capacidade não é declarada — um botão "anterior" aqui seria decorativo.
/// - **`seek` é ignorado**, como no Amazon Music: pedido para 8 s antes do fim de uma
///   faixa de 187 s, a posição continuou subindo 1 s por segundo e a faixa não trocou.
/// - **`elapsedTime` é um relógio de verdade** — o único do lote. Avança sozinho com o
///   `timestamp` acompanhando, o que dispensa qualquer estimativa local.
@MainActor
final class DeezerPlayer: MediaRemotePlayer {
    nonisolated static let bundleID = "com.deezer.deezer-desktop"

    nonisolated static let installURL: URL? = URL(string: "https://www.deezer.com/desktop")

    init() {
        super.init(bundleIdentifier: Self.bundleID, displayName: "Deezer")
    }

    override var capabilities: PlayerCapabilities { [.transport, .nextTrack] }

    override var installURL: URL? { Self.installURL }
}
