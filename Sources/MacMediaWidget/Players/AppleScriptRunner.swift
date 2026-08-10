import Foundation

/// Por que um AppleScript falhou. A distinção importa: negação de autorização é
/// permanente até o usuário mudar de ideia em Ajustes do Sistema, e faz o player
/// rebaixar suas capacidades; as outras falhas são episódicas.
enum AppleScriptError: Error {
    /// O usuário negou (ou ainda não concedeu) a permissão de Automação. `-1743`.
    case notAuthorized
    /// O app alvo não está em execução. `-600`.
    case appNotRunning
    case failed(String)
}

/// Executa AppleScript via `/usr/bin/osascript`.
///
/// Usa subprocesso em vez de `NSAppleScript` de propósito: `NSAppleScript` roda no
/// thread que o chama e um app de música lento seguraria a main thread junto com a UI
/// do widget. Em compensação cada chamada custa um `fork`/`exec`, o que torna leitura
/// por polling algo a usar com parcimônia.
enum AppleScriptRunner {
    nonisolated static func run(_ source: String) -> Result<String, AppleScriptError> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            return .failure(.failed("falha ao executar osascript: \(error)"))
        }

        // Ler antes de esperar: um pipe cheio bloqueia o processo filho, e aí o
        // `waitUntilExit` nunca retorna.
        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let out = String(data: outData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            let message = String(data: errData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if message.contains("-1743") { return .failure(.notAuthorized) }
            if message.contains("-600") { return .failure(.appNotRunning) }
            return .failure(.failed(message))
        }

        return .success(out)
    }

    /// Converte a saída de um número do AppleScript. O `osascript` formata conforme o
    /// locale, então em pt-BR uma posição de faixa volta como `12,345` — `Double(_:)`
    /// devolveria `nil` e o widget acharia que o player não tem posição.
    nonisolated static func number(from output: String?) -> Double? {
        guard let output, !output.isEmpty else { return nil }
        return Double(output.replacingOccurrences(of: ",", with: "."))
    }
}
