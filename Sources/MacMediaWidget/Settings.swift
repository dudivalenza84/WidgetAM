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

/// Tamanho do card, nos formatos da grade de widgets nativos da mesa: 1 célula
/// (quadrado, como relógio/calendário) ou 2 células de largura (como o widget de
/// previsão do tempo *medium*). O layout da UI muda junto — ver `ContentView`.
enum WidgetSize: String, CaseIterable, Identifiable {
    /// 1×1 — uma célula da grade (footprint 180×180).
    case small
    /// 2×1 — duas células de largura (footprint 360×180). Formato original do widget.
    case medium

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: return L10n.widgetSizeSmall
        case .medium: return L10n.widgetSizeMedium
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

    /// Mantém o widget sobre as janelas comuns (nível flutuante) em vez do nível de
    /// mesa dos widgets nativos.
    @Published var keepAbove: Bool {
        didSet { defaults.set(keepAbove, forKey: Keys.keepAbove) }
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

    /// Formato do card na grade de widgets nativos: 1×1 (compacto) ou 2×1 (largo).
    @Published var widgetSize: WidgetSize {
        didSet { defaults.set(widgetSize.rawValue, forKey: Keys.widgetSize) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let tintOpacity = "settings.tintOpacity"
        static let autoLaunchOnPlay = "settings.autoLaunchOnPlay"
        static let keepAbove = "settings.keepAbove"
        static let snapToGrid = "settings.snapToGrid"
        static let preferredPlayerBundleId = "settings.preferredPlayerBundleId"
        static let controlMode = "settings.controlMode"
        static let widgetSize = "settings.widgetSize"
    }

    private enum Defaults {
        static let tintOpacity: Double = 0.45
        static let autoLaunchOnPlay = true
        static let keepAbove = false
        static let snapToGrid = true
        static let preferredPlayerBundleId = AmazonMusicPlayer.bundleID
        static let controlMode = ControlMode.automatic
        static let widgetSize = WidgetSize.medium
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.tintOpacity: Defaults.tintOpacity,
            Keys.autoLaunchOnPlay: Defaults.autoLaunchOnPlay,
            Keys.keepAbove: Defaults.keepAbove,
            Keys.snapToGrid: Defaults.snapToGrid,
            Keys.preferredPlayerBundleId: Defaults.preferredPlayerBundleId,
            Keys.controlMode: Defaults.controlMode.rawValue,
            Keys.widgetSize: Defaults.widgetSize.rawValue,
        ])
        tintOpacity = defaults.double(forKey: Keys.tintOpacity)
        autoLaunchOnPlay = defaults.bool(forKey: Keys.autoLaunchOnPlay)
        keepAbove = defaults.bool(forKey: Keys.keepAbove)
        snapToGrid = defaults.bool(forKey: Keys.snapToGrid)
        preferredPlayerBundleId = defaults.string(forKey: Keys.preferredPlayerBundleId)
            ?? Defaults.preferredPlayerBundleId
        controlMode = defaults.string(forKey: Keys.controlMode)
            .flatMap(ControlMode.init(rawValue:)) ?? Defaults.controlMode
        widgetSize = defaults.string(forKey: Keys.widgetSize)
            .flatMap(WidgetSize.init(rawValue:)) ?? Defaults.widgetSize
    }
}
