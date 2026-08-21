import AppKit

/// Safari como fonte de reprodução.
///
/// Tem uma peculiaridade que nenhum outro player da lista tem: **a sessão de Now Playing
/// não sai sob o bundle id do app**. Quem publica é `com.apple.WebKit.GPU`, o processo
/// auxiliar de mídia do WebKit — que não é um app instalável, não tem ícone e cujo nome
/// resolve para `com.apple.WebKit.GPU.xpc`. Sem esta classe, o Safari tocando aparecia no
/// widget com esse identificador cru (medido em `2026-08-21 · #01`).
///
/// Por isso o `bundleIdentifier` aqui é o do processo — é ele que casa com o stream — e o
/// `applicationURL` aponta para o Safari de verdade, de onde saem ícone, nome e abertura.
///
/// E o Safari **não** é o Chrome: no mesmo teste, com um Mix do YouTube, `next` e
/// `previous` trocaram de faixa (o Chrome ignora um e rebobina no outro) e o seek moveu a
/// mídia — a faixa terminou logo depois de ser posicionada a 10 s do fim. Copiar o perfil
/// de um navegador para o outro teria errado nas duas pontas, o que é exatamente o motivo
/// de o Safari ter ficado fora do catálogo até ser medido.
@MainActor
final class SafariPlayer: MediaRemotePlayer {
    /// Quem publica a sessão. Não é `com.apple.Safari`.
    nonisolated static let sessionID = "com.apple.WebKit.GPU"

    /// O app de verdade, para ícone, nome e abertura.
    nonisolated static let appID = "com.apple.Safari"

    init() {
        super.init(bundleIdentifier: Self.sessionID, displayName: "Safari")
    }

    /// Transporte completo, seek e estado de reprodução confiável — os três medidos
    /// contra a própria página, com o JavaScript por Apple Events ligado.
    ///
    /// `.reliablePlaybackState` **é** declarado, ao contrário do Chrome: pausando e
    /// retomando pelo `<video>` (sem passar pelo MediaRemote), o campo `playing` do
    /// payload acompanhou nos três estados. O Safari não herda a mentira do Chrome.
    ///
    /// `.streamPosition` continua fora, mas não porque o campo minta: ele é uma âncora
    /// medida **no instante `timestamp`**, e o widget hoje ancora no relógio local. Com a
    /// conta certa — `elapsedTime + (agora − timestamp)` — a posição do Safari se
    /// reconstrói com menos de 1 s de erro (medido em três leituras). Está em
    /// `PENDENCIAS.md`.
    override var capabilities: PlayerCapabilities {
        [.fullTransport, .seek, .reliablePlaybackState]
    }

    override var applicationURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.appID)
    }
}
