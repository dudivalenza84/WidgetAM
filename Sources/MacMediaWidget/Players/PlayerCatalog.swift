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
    /// Id sintético: o YouTube Music não tem bundle id próprio de sessão — quem toca é
    /// o navegador (`DECISOES.md · 2026-08-19 · #01`).
    static let youTubeMusicID = "service.youtube.music"

    /// Bundle id do PWA do YouTube Music instalado pelo Chrome. Serve só para abrir —
    /// a sessão de Now Playing sai como o navegador de qualquer forma.
    static let youTubeMusicPWA = "com.google.Chrome.app.cinhimbnkkaeohfgghhklpknlkffjgod"

    private static let youTubeMusicURL = URL(string: "https://music.youtube.com")!

    /// Bundle id do Chrome. O Safari tem entrada própria, com a peculiaridade de
    /// publicar a sessão sob outro identificador (ver `SafariPlayer`).
    static let chromeID = "com.google.Chrome"

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
            PlayerCatalogEntry(
                id: TidalPlayer.bundleID,
                displayName: "TIDAL",
                kind: .app,
                installURL: TidalPlayer.installURL,
                make: { TidalPlayer() }
            ),
            PlayerCatalogEntry(
                id: DeezerPlayer.bundleID,
                displayName: "Deezer",
                kind: .app,
                installURL: DeezerPlayer.installURL,
                make: { DeezerPlayer() }
            ),
            PlayerCatalogEntry(
                id: chromeID,
                displayName: "Google Chrome",
                kind: .app,
                installURL: URL(string: "https://www.google.com/chrome/"),
                make: { BrowserPlayer(bundleIdentifier: chromeID, displayName: "Google Chrome") }
            ),
            PlayerCatalogEntry(
                id: SafariPlayer.sessionID,
                displayName: "Safari",
                kind: .app,
                installURL: nil,
                make: { SafariPlayer() }
            ),
            PlayerCatalogEntry(
                id: youTubeMusicID,
                displayName: "YouTube Music",
                kind: .shortcut(.appElseURL(bundleID: youTubeMusicPWA, url: youTubeMusicURL)),
                installURL: nil,
                make: {
                    BrowserPlayer(
                        bundleIdentifier: youTubeMusicPWA,
                        displayName: "YouTube Music",
                        catalogID: youTubeMusicID,
                        serviceURL: youTubeMusicURL
                    )
                }
            ),
        ]
    }

    /// Nome do navegador que o widget sabe controlar, para explicar ao usuário para
    /// onde ir quando ele escolhe um serviço web.
    static var browserDisplayName: String {
        entry(for: chromeID)?.displayName ?? "Google Chrome"
    }

    static func entry(for id: String) -> PlayerCatalogEntry? {
        entries.first { $0.id == id }
    }

    /// Todo id que o catálogo já cobre, para "fonte descoberta" não repetir o que já
    /// está na lista de conhecidos.
    ///
    /// Não basta olhar `entry.id`: um atalho é escolhido pelo id sintético mas **abre**
    /// outro bundle, e é esse bundle que aparece no Now Playing. Sem contar os dois, o
    /// PWA do YouTube Music entra como descoberta e a lista mostra "YouTube Music" duas
    /// vezes (visto ao vivo em `2026-08-21 · #01`).
    static var coveredIDs: Set<String> {
        var ids = Set<String>()
        for entrada in entries {
            ids.insert(entrada.id)
            if case .shortcut(let destino) = entrada.kind,
               case .appElseURL(let bundleID, _) = destino {
                ids.insert(bundleID)
            }
        }
        return ids
    }

    /// Esta entrada é um serviço hospedado em outro app?
    ///
    /// Importa para a UI: um atalho é escolhível e lançável, mas **nunca** vai ser a
    /// sessão de Now Playing, então promessas que dependem de sessão precisam ser
    /// explicadas em vez de simplesmente falharem em silêncio.
    static func isShortcut(_ id: String) -> Bool {
        guard let entrada = entry(for: id) else { return false }
        if case .shortcut = entrada.kind { return true }
        return false
    }

    /// Só as entradas que identificam sessão de Now Playing.
    static var appEntries: [PlayerCatalogEntry] {
        entries.filter { if case .app = $0.kind { return true } else { return false } }
    }
}
