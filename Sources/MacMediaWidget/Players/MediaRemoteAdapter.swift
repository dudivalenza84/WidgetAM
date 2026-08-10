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
    private static let brewPrefixes = [
        "/opt/homebrew/opt/media-control", // Apple Silicon
        "/usr/local/opt/media-control",    // Intel
    ]

    /// Diretório `mediaremote-adapter/` dentro de Resources do bundle.
    /// Em desenvolvimento (rodando o binário SPM solto), cai na instalação do brew.
    private static func adapterDir() -> String {
        if let resource = Bundle.main.resourcePath {
            let bundled = resource + "/mediaremote-adapter"
            if FileManager.default.fileExists(atPath: bundled + "/mediaremote-adapter.pl") {
                return bundled
            }
        }
        // Fallback de desenvolvimento.
        let dev = brewPrefixes.map { $0 + "/lib/media-control" }
        return dev.first { FileManager.default.fileExists(atPath: $0 + "/mediaremote-adapter.pl") }
            ?? dev[0]
    }

    static func frameworkPath() -> String {
        if let resource = Bundle.main.resourcePath {
            let bundled = resource + "/mediaremote-adapter/MediaRemoteAdapter.framework"
            if FileManager.default.fileExists(atPath: bundled) {
                return bundled
            }
        }
        let dev = brewPrefixes.map { $0 + "/Frameworks/MediaRemoteAdapter.framework" }
        return dev.first { FileManager.default.fileExists(atPath: $0) } ?? dev[0]
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

    static func send(_ command: MediaCommand) {
        run(["send", String(command.rawValue)])
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
