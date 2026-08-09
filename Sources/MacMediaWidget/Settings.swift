import Foundation
import Combine

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

    /// Ao acionar play com o `Amazon Music.app` fechado, abre-o automaticamente.
    @Published var autoLaunchOnPlay: Bool {
        didSet { defaults.set(autoLaunchOnPlay, forKey: Keys.autoLaunchOnPlay) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let tintOpacity = "settings.tintOpacity"
        static let autoLaunchOnPlay = "settings.autoLaunchOnPlay"
        static let snapToGrid = "settings.snapToGrid"
    }

    private enum Defaults {
        static let tintOpacity: Double = 0.45
        static let autoLaunchOnPlay = true
        static let snapToGrid = true
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.tintOpacity: Defaults.tintOpacity,
            Keys.autoLaunchOnPlay: Defaults.autoLaunchOnPlay,
            Keys.snapToGrid: Defaults.snapToGrid,
        ])
        tintOpacity = defaults.double(forKey: Keys.tintOpacity)
        autoLaunchOnPlay = defaults.bool(forKey: Keys.autoLaunchOnPlay)
        snapToGrid = defaults.bool(forKey: Keys.snapToGrid)
    }
}
