import Foundation
import Combine

/// Como o widget decide quem ele controla.
///
/// A distinção existe por causa de uma limitação de plataforma, não de gosto: o comando
/// do MediaRemote não tem destinatário, então no modo fixo um player sem AppleScript só
/// obedece enquanto for a sessão de Now Playing (ver `docs/fase1-multiplayer.md`).
enum ControlMode: String, CaseIterable, Identifiable {
    /// Espelha o que estiver tocando no sistema. Funciona com qualquer fonte.
    case automatic
    /// Controla sempre o player preferido, mesmo com outro app tocando — desde que o
    /// player preferido aceite comando endereçado (AppleScript).
    case fixed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .automatic: return L10n.controlModeAutomatic
        case .fixed: return L10n.controlModeFixed
        }
    }
}

/// Preferências do widget, respaldadas por `UserDefaults`. Singleton observável:
/// a UI (card e tela de configurações) e a janela reagem às mudanças ao vivo via
/// Combine, sem recompilar nem reiniciar.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    /// Quando ligado, o widget alinha-se à grade celular dos widgets nativos da
    /// mesa ao ser solto (ver NativeWidgetGrid). Desligado, fica livre na
    /// posição em que foi arrastado.
    @Published var snapToGrid: Bool {
        didSet { defaults.set(snapToGrid, forKey: Keys.snapToGrid) }
    }

    /// Intensidade da tonalização da capa sobre o card (0…1).
    @Published var tintOpacity: Double {
        didSet { defaults.set(tintOpacity, forKey: Keys.tintOpacity) }
    }

    /// Ao acionar play com o player preferido fechado, abre-o automaticamente.
    @Published var autoLaunchOnPlay: Bool {
        didSet { defaults.set(autoLaunchOnPlay, forKey: Keys.autoLaunchOnPlay) }
    }

    /// Player que o widget abre no play quando não há nada tocando — e, no modo
    /// fixo, o único que ele controla.
    @Published var preferredPlayerBundleId: String {
        didSet { defaults.set(preferredPlayerBundleId, forKey: Keys.preferredPlayerBundleId) }
    }

    /// Modo de controle: seguir quem está tocando, ou ficar preso ao player preferido.
    @Published var controlMode: ControlMode {
        didSet { defaults.set(controlMode.rawValue, forKey: Keys.controlMode) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let tintOpacity = "settings.tintOpacity"
        static let autoLaunchOnPlay = "settings.autoLaunchOnPlay"
        static let snapToGrid = "settings.snapToGrid"
        static let preferredPlayerBundleId = "settings.preferredPlayerBundleId"
        static let controlMode = "settings.controlMode"
    }

    private enum Defaults {
        static let tintOpacity: Double = 0.45
        static let autoLaunchOnPlay = true
        static let snapToGrid = true
        static let preferredPlayerBundleId = AmazonMusicPlayer.bundleID
        static let controlMode = ControlMode.automatic
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.tintOpacity: Defaults.tintOpacity,
            Keys.autoLaunchOnPlay: Defaults.autoLaunchOnPlay,
            Keys.snapToGrid: Defaults.snapToGrid,
            Keys.preferredPlayerBundleId: Defaults.preferredPlayerBundleId,
            Keys.controlMode: Defaults.controlMode.rawValue,
        ])
        tintOpacity = defaults.double(forKey: Keys.tintOpacity)
        autoLaunchOnPlay = defaults.bool(forKey: Keys.autoLaunchOnPlay)
        snapToGrid = defaults.bool(forKey: Keys.snapToGrid)
        preferredPlayerBundleId = defaults.string(forKey: Keys.preferredPlayerBundleId)
            ?? Defaults.preferredPlayerBundleId
        controlMode = defaults.string(forKey: Keys.controlMode)
            .flatMap(ControlMode.init(rawValue:)) ?? Defaults.controlMode
    }
}
