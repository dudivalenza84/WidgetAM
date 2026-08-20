import AppKit

/// Base dos players que têm dicionário AppleScript.
///
/// É a camada que existe justamente para o que o MediaRemote não entrega: posição real,
/// seek, volume por-app e — o mais importante — **comando endereçado**. Um `tell
/// application "Music"` chega no Music mesmo que quem esteja tocando seja outro app,
/// coisa impossível pelo MediaRemote (ver `MediaRemoteAdapter`).
///
/// Nada disso é garantido: se o usuário negar a permissão de Automação, todo comando
/// falha com `-1743` e o player **rebaixa as próprias capacidades** para o que o
/// MediaRemote sozinho consegue. A UI reage a isso porque lê `capabilities` a cada
/// render, em vez de decidir uma vez na inicialização.
@MainActor
class AppleScriptPlayer: MediaRemotePlayer {
    /// Nome do app no dicionário AppleScript (`tell application "<este nome>"`),
    /// que nem sempre é o nome de exibição — o Apple Music responde por "Music".
    let scriptingName: String

    /// Vira `true` no primeiro `-1743`. Não há por que insistir: a autorização só muda
    /// em Ajustes do Sistema, e cada tentativa custa um subprocesso.
    private(set) var isAuthorizationDenied = false

    init(bundleIdentifier: String, displayName: String, scriptingName: String) {
        self.scriptingName = scriptingName
        super.init(bundleIdentifier: bundleIdentifier, displayName: displayName)
    }

    /// O que este player ganha por ter AppleScript. Declarado pela subclasse, e só
    /// depois de verificado contra o app real.
    var scriptedCapabilities: PlayerCapabilities { [] }

    override var capabilities: PlayerCapabilities {
        isAuthorizationDenied
            ? PlayerCapabilities.fullTransport
            : PlayerCapabilities.fullTransport.union(scriptedCapabilities)
    }

    // MARK: - Execução

    /// Executa `tell application "<scriptingName>" to <body>` e devolve a saída.
    @discardableResult
    func tell(_ body: String) async -> String? {
        guard !isAuthorizationDenied else { return nil }
        let source = "tell application \"\(scriptingName)\" to \(body)"
        let result = await Task.detached { AppleScriptRunner.run(source) }.value

        switch result {
        case .success(let output):
            return output
        case .failure(.notAuthorized):
            isAuthorizationDenied = true
            NSLog("MacMediaWidget: automação negada para \(displayName); capacidades rebaixadas ao MediaRemote")
            return nil
        case .failure(.appNotRunning):
            return nil
        case .failure(.failed(let message)):
            NSLog("MacMediaWidget: AppleScript falhou em \(displayName): \(message)")
            return nil
        }
    }

    /// Dispara um comando sem esperar resposta.
    func fire(_ body: String) {
        Task { await tell(body) }
    }

    /// Executa só se o app já estiver rodando.
    ///
    /// Um `tell` **abre** o app alvo quando ele está fechado. Isso é desejável no play
    /// (é como o modo fixo assume o player escolhido) e indesejável em tudo o mais:
    /// apertar "próxima" não pode ressuscitar um player que o usuário fechou.
    func fireIfRunning(_ body: String) {
        guard isRunning else { return }
        fire(body)
    }
}
