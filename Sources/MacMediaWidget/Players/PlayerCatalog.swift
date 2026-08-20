import AppKit

/// Como abrir uma entrada do catálogo.
enum LaunchTarget {
    /// Abre pelo próprio bundle id da entrada.
    case app
    /// Tenta o bundle id informado; se ele não estiver instalado, abre a URL no
    /// navegador padrão. É o caso do YouTube Music, cujo PWA pode nem existir.
    case appElseURL(bundleID: String, url: URL)
}

/// O que uma entrada é do ponto de vista do sistema.
///
/// A distinção não é cosmética: ela existe porque um serviço que roda dentro do
/// navegador **não tem sessão de Now Playing própria** — quem reproduz é o processo do
/// navegador, e o MediaRemote identifica a sessão pelo processo. Ver
/// `DECISOES.md · 2026-08-19 · #01`.
enum PlayerCatalogKind {
    /// App nativo: identifica sessão de Now Playing e pode ser lançado.
    case app
    /// Serviço hospedado em outro app. Só lançável; nunca identifica sessão.
    case shortcut(LaunchTarget)
}

/// Uma entrada do catálogo de apps suportados.
struct PlayerCatalogEntry {
    /// Chave estável: o bundle id para `.app`, um id sintético para `.shortcut`.
    let id: String
    let displayName: String
    let kind: PlayerCatalogKind
    let installURL: URL?
    let make: @MainActor () -> Player
}

/// Catálogo declarativo do que o usuário pode escolher.
///
/// Separado do `PlayerRegistry` de propósito: o registry responde "quem controla esta
/// sessão", e o catálogo responde "o que o usuário pode escolher". Os dois conjuntos
/// deixaram de coincidir quando entrou o YouTube Music, que é escolhível e não é
/// sessão.
@MainActor
enum PlayerCatalog {
    static var entries: [PlayerCatalogEntry] {
        [
            PlayerCatalogEntry(
                id: AmazonMusicPlayer.bundleID,
                displayName: "Amazon Music",
                kind: .app,
                // Referencia a constante do player em vez de repetir a URL: duas cópias
                // do mesmo link divergem na primeira vez que a Amazon mudar o endereço.
                installURL: AmazonMusicPlayer.installURL,
                make: { AmazonMusicPlayer() }
            ),
            PlayerCatalogEntry(
                id: AppleMusicPlayer.bundleID,
                displayName: "Apple Music",
                kind: .app,
                installURL: nil,
                make: { AppleMusicPlayer() }
            ),
            PlayerCatalogEntry(
                id: SpotifyPlayer.bundleID,
                displayName: "Spotify",
                kind: .app,
                installURL: SpotifyPlayer.installURL,
                make: { SpotifyPlayer() }
            ),
        ]
    }

    static func entry(for id: String) -> PlayerCatalogEntry? {
        entries.first { $0.id == id }
    }

    /// Só as entradas que identificam sessão de Now Playing.
    static var appEntries: [PlayerCatalogEntry] {
        entries.filter { if case .app = $0.kind { return true } else { return false } }
    }
}
