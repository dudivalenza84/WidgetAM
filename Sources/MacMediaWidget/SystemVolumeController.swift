import Foundation
import Combine

/// Controla o **volume de saída do sistema** (global, não por-app) via AppleScript
/// `set volume`. O MediaRemote não expõe volume e não há volume por-app sem driver
/// de áudio virtual; por isso o ajuste afeta o volume do Mac inteiro.
///
/// O valor `volume` (0...1) é publicado para a UI e aplicado de forma assíncrona e
/// coalescida (só o último valor pendente é enviado), para o slider não disparar um
/// `osascript` por frame de arrasto.
@MainActor
final class SystemVolumeController: ObservableObject {
    /// Volume de saída, 0...1.
    @Published private(set) var volume: Double = 0.5
    /// Mudo de saída do sistema.
    @Published private(set) var isMuted: Bool = false

    /// Coalescência: trabalho de aplicação agendado mais recente.
    private var pendingVolume: Int?
    private var applyScheduled = false

    init() {
        readCurrentState()
    }

    // MARK: - Leitura

    /// Lê volume e mudo atuais do sistema e publica na UI. Chamado na inicialização
    /// (e pode ser rechamado quando o widget reaparece).
    func readCurrentState() {
        let script = "set s to (get volume settings)\n"
            + "return (output volume of s as text) & \",\" & (output muted of s as text)"
        Task.detached {
            guard let out = Self.runOsascript(["-e", script]) else { return }
            let parts = out.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ",")
            guard parts.count == 2, let vol = Int(parts[0]) else { return }
            let muted = parts[1] == "true"
            await MainActor.run {
                self.volume = Double(vol) / 100.0
                self.isMuted = muted
            }
        }
    }

    // MARK: - Escrita

    /// Define o volume (0...1). Sair de 0 ou ajustar o slider também desfaz o mudo.
    func setVolume(_ value: Double) {
        let clamped = min(max(value, 0), 1)
        volume = clamped
        if isMuted { isMuted = false }
        scheduleApply(Int((clamped * 100).rounded()))
    }

    /// Alterna o mudo do sistema. O macOS preserva o nível ao mutar, então desmutar
    /// restaura o volume anterior sem precisarmos guardá-lo.
    func toggleMute() {
        isMuted.toggle()
        let muted = isMuted
        Task.detached {
            _ = Self.runOsascript(["-e", "set volume \(muted ? "with" : "without") output muted"])
        }
    }

    /// Agenda a aplicação do volume coalescida: mantém só o último valor e dispara
    /// uma única vez por ciclo de run loop.
    private func scheduleApply(_ level: Int) {
        pendingVolume = level
        guard !applyScheduled else { return }
        applyScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.applyScheduled = false
            guard let level = self.pendingVolume else { return }
            self.pendingVolume = nil
            Task.detached {
                _ = Self.runOsascript(["-e", "set volume output volume \(level)"])
            }
        }
    }

    // MARK: - Util

    /// Executa `osascript` com os argumentos dados e devolve o stdout (ou nil em erro).
    /// `set volume` é comando do próprio sistema — não controla outro app, logo não
    /// dispara o prompt de permissão de Automação.
    nonisolated private static func runOsascript(_ args: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = args
        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = Pipe()
        do {
            try process.run()
            let data = stdout.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return String(data: data, encoding: .utf8)
        } catch {
            NSLog("MacMediaWidget: falha ao executar osascript de volume: \(error)")
            return nil
        }
    }
}
