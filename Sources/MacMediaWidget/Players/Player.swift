import AppKit

/// O que uma fonte de reprodução permite fazer.
///
/// Nada aqui é presumido: cada capacidade declarada por um `Player` concreto foi
/// verificada contra o app real (ver `docs/compatibilidade-players.md`). A regra do
/// projeto é dura porque já custou caro — o `Amazon Music.app` **aceita** o comando de
/// seek do MediaRemote e simplesmente não faz nada com ele (`DECISOES.md · 2026-08-05 · #02`).
/// Comando aceito sem erro não é comando funcionando.
///
/// E capacidade declarada não é garantia: tudo que depende de AppleScript cai se o
/// usuário negar a permissão de Automação. Por isso `Player` expõe a lista como
/// propriedade calculada, e não como constante — quem implementa pode rebaixá-la em
/// runtime ao descobrir que não tem autorização.
struct PlayerCapabilities: OptionSet, Sendable {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }

    /// play e pause.
    static let transport = PlayerCapabilities(rawValue: 1 << 0)
    /// Pula para a faixa seguinte. Separado de `.transport` porque **não** vem junto:
    /// no navegador o `nextTrack` do MediaRemote não faz nada, com o vídeo seguindo em
    /// frente como se nada tivesse sido pedido (`docs/compatibilidade-players.md`).
    static let nextTrack = PlayerCapabilities(rawValue: 1 << 6)
    /// Volta para a faixa anterior. Também separado: o Deezer ignora o comando (nem
    /// troca de faixa nem reinicia a atual) e o navegador **rebobina** a mídia em vez
    /// de trocar — nos dois casos o botão seria decorativo.
    static let previousTrack = PlayerCapabilities(rawValue: 1 << 7)
    /// Sabe dizer a posição real da faixa quando perguntado, em vez de estimá-la
    /// localmente. Custa um subprocesso por leitura: hoje só a camada AppleScript tem.
    static let realPosition = PlayerCapabilities(rawValue: 1 << 1)
    /// O `elapsedTime` que a fonte publica no stream do MediaRemote é **confiável** e
    /// serve de âncora para a barra. Chega de graça, sem subprocesso nenhum.
    ///
    /// Não é redundante com `.realPosition` nem implicada por ela: o Amazon Music
    /// simplesmente não publica o campo, e o navegador publica **mentindo** — deixa o
    /// valor em zero com o `timestamp` congelado enquanto o vídeo corre. Ancorar ali
    /// mostraria a barra parada no início para sempre.
    static let streamPosition = PlayerCapabilities(rawValue: 1 << 8)
    /// O campo `playing` do stream diz a verdade sobre esta fonte.
    ///
    /// Vale para todo app nativo medido. Não vale para o navegador: houve leitura de
    /// `playing=True` com o vídeo comprovadamente pausado na página
    /// (`docs/compatibilidade-players.md`, nota ⁶). Sem esta capacidade o widget para de
    /// afirmar o estado — o botão vira o símbolo neutro de alternância e a barra não
    /// corre sozinha — em vez de mostrar com convicção o oposto do que está acontecendo.
    static let reliablePlaybackState = PlayerCapabilities(rawValue: 1 << 9)
    /// Aceita mover a posição da faixa.
    static let seek = PlayerCapabilities(rawValue: 1 << 2)
    /// Tem volume próprio, independente do volume de saída do sistema.
    static let appVolume = PlayerCapabilities(rawValue: 1 << 3)
    /// Expõe os modos de aleatório e repetição.
    static let shuffleRepeat = PlayerCapabilities(rawValue: 1 << 4)
    /// Aceita comando mesmo sem ser a sessão de Now Playing do sistema.
    ///
    /// É a capacidade que separa as duas camadas: o comando do MediaRemote **não tem
    /// destinatário** — atua sobre a sessão ativa, seja ela qual for. Só quem tem
    /// AppleScript pode ser endereçado diretamente.
    static let directedControl = PlayerCapabilities(rawValue: 1 << 5)

    /// Transporte completo: play/pause mais as duas trocas de faixa. É o que se espera
    /// de um player qualquer, e o que o MediaRemote oferece por padrão — quem foi
    /// medido faltando alguma peça declara o conjunto na mão, sem este atalho.
    static let fullTransport: PlayerCapabilities = [.transport, .nextTrack, .previousTrack]
}

/// Uma fonte de reprodução controlável pelo widget.
///
/// A leitura de metadados **não** passa por aqui: ela vem sempre do stream do
/// MediaRemote (`NowPlayingController`), que funciona com qualquer fonte, inclusive
/// as que este código nunca ouviu falar. O protocolo cobre só o que se **manda** para
/// o player, mais as leituras que o MediaRemote não entrega (posição real e volume).
@MainActor
protocol Player: AnyObject {
    /// Bundle id do app. É a chave que liga o payload do stream a esta implementação.
    var bundleIdentifier: String { get }
    /// Chave desta fonte no `PlayerCatalog` — e, por tabela, em tudo que o usuário
    /// escolhe ou oculta (`preferredPlayerBundleId`, lista de ocultos, menu "Trocar
    /// app"). Igual ao `bundleIdentifier` em todo player que é um app de verdade; só
    /// difere nos atalhos de serviço web, cujo id de catálogo é sintético porque o
    /// serviço não tem processo próprio (`PlayerCatalog.youTubeMusicID`).
    var catalogID: String { get }
    /// Nome para exibir na UI.
    var displayName: String { get }
    var capabilities: PlayerCapabilities { get }

    func playPause()
    func play()
    func next()
    func previous()

    /// Move a posição da faixa. Só faz sentido com `.seek` nas capacidades.
    func seek(to seconds: Double)
    /// Posição real da faixa. `nil` quando a fonte não a expõe — nesse caso quem
    /// estima é o `NowPlayingController`.
    func position() async -> Double?

    /// Volume do próprio app (0…1). `nil` quando a fonte não tem volume próprio.
    func volume() async -> Double?
    func setVolume(_ value: Double)

    /// Página de instalação do app, quando o produto sabe indicar uma.
    var installURL: URL? { get }
    /// Abre (ou traz à frente) o app. `false` quando não está instalado — nesse caso
    /// o usuário já foi avisado por `promptInstall()`.
    @discardableResult func launch() -> Bool
    func promptInstall()
}

extension Player {
    // Defaults para quem não tem a capacidade: silêncio, não erro. Quem chama já
    // consultou `capabilities` — estes corpos vazios existem para que uma chamada
    // indevida seja inócua, e não um crash.
    func seek(to seconds: Double) {}
    func position() async -> Double? { nil }
    func volume() async -> Double? { nil }
    func setVolume(_ value: Double) {}

    /// Um app é sua própria entrada no catálogo; atalho sobrescreve.
    var catalogID: String { bundleIdentifier }

    /// URL do app instalado, se houver.
    var applicationURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    var isInstalled: Bool { applicationURL != nil }

    /// Sob simulação de app ausente responde `false`: um app "não instalado" não pode
    /// estar rodando, e sem isso o teste nunca alcançaria o caminho do alerta.
    var isRunning: Bool {
        if DebugFlags.simulatesMissingApp { return false }
        return !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
    }

    /// Ícone do app, para a UI indicar a fonte ativa.
    var icon: NSImage? {
        guard let url = applicationURL else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    /// Nome do app conforme o Finder, quando não há um nome fixo melhor.
    static func localizedName(forBundleIdentifier id: String) -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) else {
            return nil
        }
        return FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")
    }

    // MARK: - Instalação e abertura

    var installURL: URL? { nil }

    @discardableResult
    func launch() -> Bool {
        guard !DebugFlags.simulatesMissingApp, let url = applicationURL else {
            NSLog("MacMediaWidget: \(displayName) não encontrado (\(bundleIdentifier))")
            promptInstall()
            return false
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config)
        return true
    }

    /// Avisa que o app não está instalado e, quando há uma página de instalação
    /// conhecida, oferece abri-la.
    func promptInstall() {
        let name = displayName
        let url = installURL
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = L10n.notInstalledTitle(name)
            alert.informativeText = url == nil
                ? L10n.notInstalledBody(name)
                : L10n.notInstalledBodyWithLink(name)
            alert.alertStyle = .warning
            if url != nil { alert.addButton(withTitle: L10n.openInstallPage) }
            alert.addButton(withTitle: url == nil ? L10n.ok : L10n.cancel)
            // O app roda como `.accessory` (sem Dock): sem ativar explicitamente,
            // o alerta pode nascer atrás das outras janelas e não haveria ícone
            // no Dock para resgatá-lo.
            NSApp.activate()
            if alert.runModal() == .alertFirstButtonReturn, let url {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

/// Chaves de teste que forçam caminhos difíceis de reproduzir de verdade.
enum DebugFlags {
    /// Força o caminho de "app não instalado", para testar o alerta sem desinstalar
    /// nada. Ligar/desligar com:
    ///
    ///     defaults write com.dudivalenza.macmediawidget simulateMissingApp -bool YES
    ///     defaults delete com.dudivalenza.macmediawidget simulateMissingApp
    ///
    /// A variável de ambiente serve para rodar o binário direto; a chave de
    /// `UserDefaults` sobrevive ao relançamento do bundle pelo LaunchServices.
    /// Fora de debug é sempre `false`: uma chave de teste que altera o comportamento do
    /// app e pode ser ligada por qualquer processo que escreva no domínio de
    /// `UserDefaults` não tem por que existir num binário distribuído.
    static var simulatesMissingApp: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["MMW_SIMULATE_MISSING_APP"] != nil
            || UserDefaults.standard.bool(forKey: "simulateMissingApp")
        #else
        return false
        #endif
    }
}
