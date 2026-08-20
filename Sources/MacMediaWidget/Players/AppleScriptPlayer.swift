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

    /// O que continua valendo **sem** AppleScript — o que vem pelo MediaRemote. É o
    /// piso quando a automação é negada, e por isso não pode ficar em
    /// `scriptedCapabilities`: o `elapsedTime` que a fonte publica no stream não
    /// depende de permissão nenhuma.
    var unscriptedCapabilities: PlayerCapabilities { [.fullTransport, .reliablePlaybackState] }

    override var capabilities: PlayerCapabilities {
        isAuthorizationDenied
            ? unscriptedCapabilities
            : unscriptedCapabilities.union(scriptedCapabilities)
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

    #if DEBUG
    /// Força o estado de Automação negada. Existe porque o caminho real — revogar a
    /// permissão em Ajustes do Sistema — não é reproduzível num teste, e o rebaixamento
    /// é justamente onde o transporte já ficou mudo uma vez (`PENDENCIAS.md`,
    /// `2026-08-20 · #01`).
    func simulateAuthorizationDenied() { isAuthorizationDenied = true }
    #endif

    // MARK: - Vocabulário da iTunes suite
    //
    // Music.app e Spotify falam o mesmo dicionário nestes verbos — `playpause`, `play`,
    // `next track`, `previous track`, `player position` e `sound volume`. Por isso a
    // implementação mora aqui, e a subclasse declara apenas as capacidades que foram
    // medidas. Um player com vocabulário diferente sobrescreve o que precisar.
    //
    // Chamar um destes num player sem a capacidade correspondente é inócuo: quem chama
    // consultou `capabilities` antes.

    var playPauseCommand: String { "playpause" }
    var playCommand: String { "play" }
    var nextCommand: String { "next track" }
    /// `previous track` vai para a faixa anterior; `back track` voltaria ao início da
    /// atual. O botão do widget é "anterior", então é `previous track`.
    var previousCommand: String { "previous track" }

    // MARK: - Transporte
    //
    // Vai por AppleScript, e não pelo MediaRemote, porque é **endereçado**: funciona
    // mesmo quando outro app é a sessão de Now Playing. É o que dá sentido ao modo fixo.
    //
    // Com a Automação negada, cai para o MediaRemote — que é o que `capabilities` passa
    // a prometer nesse estado. Sem este fallback o comando viraria no-op silencioso:
    // `tell` retorna sem executar nada assim que `isAuthorizationDenied` vira `true`, e
    // o widget ficaria oferecendo botões de transporte que não fazem coisa alguma.

    override func playPause() {
        guard !isAuthorizationDenied else { return super.playPause() }
        fireIfRunning(playPauseCommand)
    }

    /// O único comando que pode abrir o app: é o play do widget assumindo o player.
    override func play() {
        guard !isAuthorizationDenied else { return super.play() }
        fire(playCommand)
    }

    override func next() {
        guard !isAuthorizationDenied else { return super.next() }
        fireIfRunning(nextCommand)
    }

    override func previous() {
        guard !isAuthorizationDenied else { return super.previous() }
        fireIfRunning(previousCommand)
    }

    // MARK: - Posição

    override func position() async -> Double? {
        guard isRunning else { return nil }
        return AppleScriptRunner.number(from: await tell("get player position"))
    }

    /// Aqui o fallback vale mais do que no transporte: Apple Music e Spotify **também**
    /// obedecem ao seek do MediaRemote (medido nos dois), então a barra continua
    /// arrastável mesmo sem Automação — desde que o player seja a sessão ativa, que é o
    /// que `NowPlayingController.canControlTransport` garante antes de chamar.
    override func seek(to seconds: Double) {
        guard !isAuthorizationDenied else { return super.seek(to: seconds) }
        fireIfRunning("set player position to \(Int(seconds.rounded()))")
    }

    // MARK: - Volume por-app (0–100 no dicionário, 0…1 no protocolo)
    //
    // Sem fallback: o MediaRemote não tem volume, e `capabilities` já deixa de prometer
    // `.appVolume` quando a Automação cai — o `VolumeRouter` passa a mexer no volume de
    // saída do sistema por conta própria.

    override func volume() async -> Double? {
        guard isRunning else { return nil }
        guard let level = AppleScriptRunner.number(from: await tell("get sound volume")) else {
            return nil
        }
        return level / 100
    }

    override func setVolume(_ value: Double) {
        let level = Int((min(max(value, 0), 1) * 100).rounded())
        fireIfRunning("set sound volume to \(level)")
    }
}
