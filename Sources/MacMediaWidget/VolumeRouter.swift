import Combine
import Foundation

/// Decide se o slider do widget mexe no volume do app ou no do sistema, e mantém o
/// valor exibido em dia com o alvo.
///
/// Existe porque o mesmo controle passa a ter dois significados: no Apple Music mexe no
/// volume daquele app; no Amazon Music — que não tem AppleScript — não há volume próprio
/// e só resta o volume de saída do Mac inteiro. A UI mostra qual é o alvo em vez de
/// disfarçar a diferença.
@MainActor
final class VolumeRouter: ObservableObject {
    enum Target: Equatable {
        case system
        case app(String)

        var isApp: Bool { if case .app = self { return true }; return false }

        var label: String {
            switch self {
            case .system: return "Volume do sistema"
            case .app(let name): return "Volume do \(name)"
            }
        }
    }

    @Published private(set) var volume: Double = 0.5
    @Published private(set) var isMuted = false
    @Published private(set) var target: Target = .system

    private let system = SystemVolumeController()
    /// Player alvo quando o volume é por-app.
    private var appPlayer: Player?
    /// Volume anterior ao mute por-app: o app não tem "mudo", então mudo é volume 0 e
    /// desfazer exige lembrar de onde veio. (No sistema o macOS já preserva o nível.)
    private var volumeBeforeAppMute: Double?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Enquanto o alvo é o sistema, o router é um espelho do SystemVolumeController.
        system.$volume
            .sink { [weak self] value in
                guard let self, !self.target.isApp else { return }
                self.volume = value
            }
            .store(in: &cancellables)

        system.$isMuted
            .sink { [weak self] muted in
                guard let self, !self.target.isApp else { return }
                self.isMuted = muted
            }
            .store(in: &cancellables)
    }

    /// Reavalia o alvo a partir do player que o widget controla agora.
    func retarget(to player: Player?) {
        let usesAppVolume = player?.capabilities.contains(.appVolume) == true
            && player?.isRunning == true

        let newTarget: Target = usesAppVolume && player != nil
            ? .app(player!.displayName)
            : .system

        let changed = newTarget != target
        target = newTarget
        appPlayer = usesAppVolume ? player : nil

        if changed { volumeBeforeAppMute = nil }
        refresh()
    }

    /// Relê o volume do alvo atual.
    func refresh() {
        guard let appPlayer else {
            system.readCurrentState()
            return
        }
        Task { [weak self] in
            guard let value = await appPlayer.volume() else { return }
            guard let self, self.target.isApp else { return }
            self.volume = value
            self.isMuted = value == 0
        }
    }

    // MARK: - Escrita

    func setVolume(_ value: Double) {
        let clamped = min(max(value, 0), 1)
        volume = clamped
        if isMuted { isMuted = false }
        volumeBeforeAppMute = nil

        if let appPlayer {
            appPlayer.setVolume(clamped)
        } else {
            system.setVolume(clamped)
        }
    }

    func toggleMute() {
        guard let appPlayer else {
            system.toggleMute()
            return
        }
        if isMuted {
            let restored = volumeBeforeAppMute ?? 0.5
            volumeBeforeAppMute = nil
            isMuted = false
            volume = restored
            appPlayer.setVolume(restored)
        } else {
            volumeBeforeAppMute = volume
            isMuted = true
            volume = 0
            appPlayer.setVolume(0)
        }
    }
}
