import AppKit

/// `Amazon Music.app` — a razão de existir do widget, e o player mais limitado da lista.
///
/// Não expõe dicionário AppleScript (`NSAppleScriptEnabled` ausente, sem `.sdef`), então
/// não há como endereçá-lo diretamente nem ler/gravar posição ou volume por-app. Além
/// disso ignora o comando de seek do MediaRemote e não publica `elapsedTime`
/// (`DECISOES.md · 2026-08-05 · #01` e `#02`). Sobra o transporte pela sessão ativa —
/// exatamente o que o `MediaRemotePlayer` já faz.
@MainActor
final class AmazonMusicPlayer: MediaRemotePlayer {
    /// `nonisolated` porque é lido de contexto sem ator — o valor padrão de
    /// `AppSettings`, que é construído antes de qualquer isolamento de main actor.
    nonisolated static let bundleID = "com.amazon.music"

    init() {
        super.init(bundleIdentifier: Self.bundleID, displayName: "Amazon Music")
    }

    /// URL oficial de download do Amazon Music para desktop. A página
    /// `music.amazon.com/download` dava 404 (`2026-06-24 · #01`).
    ///
    /// `static` para o `PlayerCatalog` referenciar a mesma constante sem instanciar o
    /// player — e sem manter uma segunda cópia da URL.
    nonisolated static let installURL: URL? =
        URL(string: "https://am.app.link/zb0Bk69BNub/?__branch_flow_type=qr_code")

    override var installURL: URL? { Self.installURL }
}
