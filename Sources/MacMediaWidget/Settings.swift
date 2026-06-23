import Foundation
import Combine

/// Preferências do widget, respaldadas por `UserDefaults`. Singleton observável:
/// a UI (card e tela de configurações) e a janela reagem às mudanças ao vivo via
/// Combine, sem recompilar nem reiniciar.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    /// Distância da borda da tela até a borda visível do card, em pontos. Antes
    /// uma constante empírica; agora ajustável (resolve a calibração do snap).
    @Published var edgeMargin: CGFloat {
        didSet { defaults.set(Double(edgeMargin), forKey: Keys.edgeMargin) }
    }

    /// Passo do alinhamento vertical do snap, em pontos.
    @Published var gridStepY: CGFloat {
        didSet { defaults.set(Double(gridStepY), forKey: Keys.gridStepY) }
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
        static let edgeMargin = "settings.edgeMargin"
        static let gridStepY = "settings.gridStepY"
        static let tintOpacity = "settings.tintOpacity"
        static let autoLaunchOnPlay = "settings.autoLaunchOnPlay"
    }

    private enum Defaults {
        static let edgeMargin: CGFloat = 16
        static let gridStepY: CGFloat = 8
        static let tintOpacity: Double = 0.45
        static let autoLaunchOnPlay = true
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.edgeMargin: Double(Defaults.edgeMargin),
            Keys.gridStepY: Double(Defaults.gridStepY),
            Keys.tintOpacity: Defaults.tintOpacity,
            Keys.autoLaunchOnPlay: Defaults.autoLaunchOnPlay,
        ])
        edgeMargin = CGFloat(defaults.double(forKey: Keys.edgeMargin))
        gridStepY = CGFloat(defaults.double(forKey: Keys.gridStepY))
        tintOpacity = defaults.double(forKey: Keys.tintOpacity)
        autoLaunchOnPlay = defaults.bool(forKey: Keys.autoLaunchOnPlay)
    }
}
