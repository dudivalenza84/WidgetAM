import Foundation

/// IDs de comando do MediaRemote (MRCommand). Repassados ao adapter via `send`.
enum MediaCommand: Int {
    case play = 0
    case pause = 1
    case togglePlayPause = 2
    case nextTrack = 4
    case previousTrack = 5
}

/// Acesso ao `mediaremote-adapter`: resolve os caminhos dos recursos bundlados e
/// executa o `mediaremote-adapter.pl` via `/usr/bin/perl` (o único perl da máquina
/// com as entitlements do MediaRemote).
///
/// Um detalhe que define a arquitetura toda: **`send` não tem destinatário**. O
/// comando vai para a sessão de Now Playing do sistema, seja ela qual for — não há
/// parâmetro de bundle id em lugar nenhum do adapter. Mandar um comando "para o
/// Spotify" enquanto o Amazon Music toca é impossível por aqui; só AppleScript
/// endereça um app específico.
enum MediaRemoteAdapter {
    private static let perlPath = "/usr/bin/perl"

    /// Prefixos do brew para o `media-control`, na ordem de tentativa. São os
    /// symlinks `opt/`, que o brew reaponta a cada atualização da fórmula —
    /// diferente de um caminho no `Cellar/`, que carrega a versão no nome e
    /// deixa de existir no primeiro `brew upgrade`. Mesma resolução que o
    /// `brew --prefix media-control` usado pelo `scripts/build-app.sh`.
    ///
    /// **Só existe em debug, e isso é uma decisão de segurança.** `/opt/homebrew` é
    /// gravável pelo usuário comum no Apple Silicon: qualquer processo sem privilégio
    /// pode escrever lá. Se o app distribuído aceitasse esse caminho como alternativa —
    /// nem que fosse só quando o recurso bundlado sumisse —, bastaria plantar um
    /// `mediaremote-adapter.pl` ali para executar código arbitrário **dentro** do
    /// processo do widget, herdando as permissões dele, inclusive a de Automação sobre
    /// os apps de música. Em release, o recurso do bundle é o único caminho aceito; se
    /// ele não estiver lá, o app fica sem leitura e diz isso, que é o comportamento
    /// seguro.
    #if DEBUG
    private static let brewPrefixes = [
        "/opt/homebrew/opt/media-control", // Apple Silicon
        "/usr/local/opt/media-control",    // Intel
    ]
    #endif

    /// Diretório `mediaremote-adapter/` dentro de Resources do bundle.
    /// Em desenvolvimento (rodando o binário SPM solto), cai na instalação do brew.
    private static func adapterDir() -> String {
        if let resource = Bundle.main.resourcePath {
            let bundled = resource + "/mediaremote-adapter"
            if FileManager.default.fileExists(atPath: bundled + "/mediaremote-adapter.pl") {
                return bundled
            }
        }
        #if DEBUG
        let dev = brewPrefixes.map { $0 + "/lib/media-control" }
        return dev.first { FileManager.default.fileExists(atPath: $0 + "/mediaremote-adapter.pl") }
            ?? dev[0]
        #else
        // Caminho inexistente: o subprocesso falha ao iniciar, a saúde do adapter vira
        // `.unavailable` e o usuário é avisado — em vez de executarmos um script de
        // procedência desconhecida.
        return (Bundle.main.resourcePath ?? "") + "/mediaremote-adapter"
        #endif
    }

    static func frameworkPath() -> String {
        if let resource = Bundle.main.resourcePath {
            let bundled = resource + "/mediaremote-adapter/MediaRemoteAdapter.framework"
            if FileManager.default.fileExists(atPath: bundled) {
                return bundled
            }
        }
        #if DEBUG
        let dev = brewPrefixes.map { $0 + "/Frameworks/MediaRemoteAdapter.framework" }
        return dev.first { FileManager.default.fileExists(atPath: $0) } ?? dev[0]
        #else
        return (Bundle.main.resourcePath ?? "") + "/mediaremote-adapter/MediaRemoteAdapter.framework"
        #endif
    }

    static func scriptPath() -> String {
        adapterDir() + "/mediaremote-adapter.pl"
    }

    /// Monta (sem iniciar) o processo do stream contínuo de Now Playing.
    static func makeStreamProcess() -> Process {
        makeProcess(["stream"])
    }

    /// Executa o adapter de forma efêmera (comandos one-shot) e ignora a saída.
    static func run(_ arguments: [String]) {
        let process = makeProcess(arguments)
        do {
            try process.run()
        } catch {
            NSLog("MacMediaWidget: falha ao enviar comando ao adapter: \(error)")
        }
    }

    #if DEBUG
    /// Desvia os comandos em vez de executá-los, para o `SelfTests` observar **para onde**
    /// um player roteia sem disparar subprocesso nem mexer na música de quem está
    /// rodando o teste. `nil` fora do teste, que é o caminho normal.
    nonisolated(unsafe) static var commandSink: ((MediaCommand) -> Void)?
    #endif

    static func send(_ command: MediaCommand) {
        #if DEBUG
        if let commandSink {
            commandSink(command)
            return
        }
        #endif
        run(["send", String(command.rawValue)])
    }

    /// Move a posição da sessão ativa. O adapter espera **microssegundos**.
    ///
    /// Como todo comando daqui, vai para quem estiver com a sessão — e como todo
    /// comando daqui, ser aceito não é ser obedecido: Amazon Music e Deezer engolem
    /// este pedido sem mover nada (`docs/compatibilidade-players.md`). Por isso quem
    /// chama precisa ter `.seek` nas capacidades, declarada só com evidência.
    static func seek(to seconds: Double) {
        let microseconds = Int64((max(seconds, 0) * 1_000_000).rounded())
        run(["seek", String(microseconds)])
    }

    /// Pergunta ao adapter se ele ainda consegue falar com o MediaRemote.
    ///
    /// É a checagem que distingue "nenhuma música tocando" de "o mecanismo do app parou
    /// de existir" — o risco estrutural do produto, já que o MediaRemote é framework
    /// privado e a Apple pode fechar o acesso num update do macOS. Sem isto, uma quebra
    /// dessas apareceria para o usuário como um widget eternamente vazio.
    nonisolated static func isEntitled() -> Bool {
        let process = makeProcess(["test"])
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private static func makeProcess(_ arguments: [String]) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: perlPath)
        process.arguments = [scriptPath(), frameworkPath()] + arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        return process
    }
}
