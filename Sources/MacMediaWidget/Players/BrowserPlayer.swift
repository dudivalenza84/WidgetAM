import AppKit

/// Navegador como fonte de reprodução.
///
/// Chrome e Safari têm AppleScript, mas **nenhuma capacidade de mídia** — o que existe
/// é `execute javascript`, que depende de uma opção do menu Desenvolvedor ligada à mão
/// e por isso não serve como recurso de produto (`docs/fase1-multiplayer.md` §2). Sobra
/// o MediaRemote, e nele o navegador é um caso à parte
/// (`docs/compatibilidade-players.md`):
/// - play/pause e **seek funcionam** — o seek foi confirmado lendo o `currentTime` do
///   `<video>` na própria página, não o payload do Now Playing;
/// - **`nextTrack` não faz nada** e **`previousTrack` rebobina** a mídia atual em vez
///   de trocar. Nenhuma das duas é declarada: o botão obedeceria a uma promessa que o
///   navegador não cumpre;
/// - o payload **mente** em `playing` e em `elapsedTime`, então nada aqui declara
///   `.streamPosition` nem `.reliablePlaybackState`. Sem a segunda, o widget para de
///   afirmar se a mídia está tocando: o botão vira o símbolo neutro de alternância —
///   que é o que ele de fato faz — e a barra deixa de correr por conta própria.
///
/// Esta classe também é o alvo dos atalhos de serviços web: quem toca é o navegador,
/// então é ele quem aparece como fonte — o widget não tem como saber qual aba está
/// tocando (`DECISOES.md · 2026-08-19 · #01`).
@MainActor
final class BrowserPlayer: MediaRemotePlayer {
    /// Abre a URL do serviço quando o atalho é acionado sem app dedicado instalado.
    private let serviceURL: URL?

    /// Id sintético quando esta instância representa um atalho de serviço web. O
    /// `bundleIdentifier` continua sendo o do app que abre (o PWA), porque é dele que
    /// saem ícone e caminho de instalação — mas quem o usuário escolhe e oculta é o
    /// serviço, e essa chave é outra.
    private let fixedCatalogID: String?

    init(
        bundleIdentifier: String,
        displayName: String,
        catalogID: String? = nil,
        serviceURL: URL? = nil
    ) {
        self.serviceURL = serviceURL
        self.fixedCatalogID = catalogID
        super.init(bundleIdentifier: bundleIdentifier, displayName: displayName)
    }

    override var catalogID: String { fixedCatalogID ?? bundleIdentifier }

    override var capabilities: PlayerCapabilities { [.transport, .seek] }

    /// Um atalho web sem app instalado ainda tem para onde ir: a página do serviço.
    @discardableResult
    override func launch() -> Bool {
        if applicationURL != nil { return super.launch() }
        guard let serviceURL else { return super.launch() }
        NSWorkspace.shared.open(serviceURL)
        return true
    }
}
