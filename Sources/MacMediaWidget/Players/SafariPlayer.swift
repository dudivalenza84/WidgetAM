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

    /// Transporte completo e seek, os dois observados. Sem `.streamPosition`: o
    /// `elapsedTime` do Safari fica em `0` com o vídeo correndo, igual ao do Chrome, e só
    /// se mexe depois de um seek. Sem `.reliablePlaybackState` pelo mesmo motivo de
    /// família — no Chrome o campo `playing` foi flagrado mentindo, e aqui ele não foi
    /// medido contra a página.
    override var capabilities: PlayerCapabilities { [.fullTransport, .seek] }

    override var applicationURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.appID)
    }
}
