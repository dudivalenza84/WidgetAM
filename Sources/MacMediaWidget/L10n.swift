import Foundation

/// Textos da interface, em um lugar só.
///
/// O idioma-base do código passa a ser **inglês**: a chave de cada string é o próprio
/// texto em inglês, e `Resources/pt-BR.lproj/Localizable.strings` traz a tradução. É a
/// convenção da Apple e tem uma vantagem prática aqui — rodando o binário solto em
/// desenvolvimento, sem o bundle `.app` montado, não há `.lproj` nenhum e o fallback é a
/// própria chave: a UI aparece em inglês legível, e não com identificadores crus.
///
/// Centralizar em vez de espalhar `String(localized:)` pelo código serve para que
/// traduzir (ou revisar a tradução) seja ler um arquivo, não caçar literais em nove.
enum L10n {
    // MARK: - Card

    static var nothingPlaying: String { String(localized: "Nothing playing") }
    static var noArtist: String { "—" }
    static var dragToSeek: String { String(localized: "Drag to change position") }

    // MARK: - Saúde do adapter

    static var reconnecting: String { String(localized: "Reconnecting…") }
    static var mechanismUnavailable: String {
        String(localized: "macOS is not allowing playback information to be read.")
    }

    // MARK: - Transporte indisponível

    static func playerNotInstalled(_ name: String) -> String {
        String(localized: "\(name) is not installed")
    }
    static func playerNotRunning(_ name: String) -> String {
        String(localized: "\(name) is closed")
    }
    static func playerNotPlaying(_ name: String) -> String {
        String(localized: "\(name) is not playing")
    }

    // MARK: - Fonte oculta

    static func sourceHidden(_ name: String) -> String {
        String(localized: "\(name) is playing · hidden")
    }
    static var showThisApp: String { String(localized: "Show this app") }

    // MARK: - Apps controlados

    static var sectionControlledApps: String { String(localized: "Controlled apps") }
    static var controlledAppsHelp: String {
        String(localized: "Unchecked apps disappear from the “Switch app” menu, and the widget ignores what they play.")
    }
    static var preferredCannotBeHidden: String {
        String(localized: "The preferred player is always shown")
    }
    static var notInstalled: String { String(localized: "not installed") }
    static var opensInBrowser: String { String(localized: "opens in the browser") }
    static var forgetDiscovered: String { String(localized: "Forget discovered apps") }

    // MARK: - Volume

    static var systemVolume: String { String(localized: "System volume") }
    static func appVolume(_ name: String) -> String {
        String(localized: "\(name) volume")
    }

    // MARK: - Bandeja

    static var showHideWidget: String { String(localized: "Show/hide widget") }
    static var openPlayerGeneric: String { String(localized: "Open player") }
    static func openPlayer(_ name: String) -> String {
        String(localized: "Open \(name)")
    }
    static func playingTrack(_ title: String) -> String {
        String(localized: "Playing — \(title)")
    }
    static func pausedTrack(_ title: String) -> String {
        String(localized: "Paused — \(title)")
    }
    static var previousTrack: String { String(localized: "Previous track") }
    static var playPause: String { String(localized: "Play/Pause") }
    static var nextTrack: String { String(localized: "Next track") }
    static var switchApp: String { String(localized: "Switch app") }
    static var preferences: String { String(localized: "Preferences…") }
    static var openAtLogin: String { String(localized: "Open at login") }
    static var quit: String { String(localized: "Quit") }

    // MARK: - Preferências

    static var preferencesTitle: String { String(localized: "Preferences") }
    static var sectionPlayer: String { String(localized: "Player") }
    static var preferredPlayer: String { String(localized: "Preferred player") }
    static var controlMode: String { String(localized: "Control mode") }
    static var controlModeAutomatic: String { String(localized: "Control whatever is playing") }
    static var controlModeFixed: String { String(localized: "Always control the chosen player") }
    static var controlModeAutomaticHelp: String {
        String(localized: "The widget mirrors whatever is playing, in any app. The preferred player is the one it opens when you hit play with nothing playing.")
    }
    static func controlModeFixedHelp(_ name: String) -> String {
        String(localized: "The widget always controls \(name), even with another app playing.")
    }
    static func controlModeFixedHelpLimited(_ name: String) -> String {
        String(localized: "The widget always controls \(name) — but it has no AppleScript support, so it only responds while it is the app that is playing. With another app in charge, play opens \(name) and the other controls stay inactive.")
    }

    static var sectionPlacement: String { String(localized: "Placement") }
    static var keepAbove: String { String(localized: "Keep the widget above other windows") }
    static var snapToGrid: String { String(localized: "Align to the macOS widget grid") }
    static var snapToGridHelp: String {
        String(localized: "The grid is the same one used by the desktop's native widgets: with a native widget visible, alignment is measured from it; with none, the system's default geometry is used.")
    }

    static var sectionAppearance: String { String(localized: "Appearance") }
    static var widgetSize: String { String(localized: "Widget size") }
    static var widgetSizeSmall: String { String(localized: "Compact (1×1)") }
    static var widgetSizeMedium: String { String(localized: "Wide (2×1)") }
    static var widgetSizeHelp: String {
        String(localized: "Same footprints as the desktop's native widgets: one grid cell (like the clock) or two cells wide (like the weather widget).")
    }
    static var tintOpacity: String { String(localized: "Tint opacity") }

    static var sectionBehavior: String { String(localized: "Behavior") }
    static func autoLaunchOnPlay(_ name: String) -> String {
        String(localized: "Open \(name) on play (if it is closed)")
    }
    static var fallbackPlayerName: String { String(localized: "preferred player") }
    static var bringToFrontShortcut: String { String(localized: "Bring widget to front") }
    static var bringToFrontShortcutHelp: String {
        String(localized: "Press the shortcut again to send the widget back to the desktop level.")
    }

    // MARK: - Sobre

    static var version: String { String(localized: "Version") }

    // MARK: - App não instalado

    static func notInstalledTitle(_ name: String) -> String {
        String(localized: "\(name) is not installed")
    }
    static func notInstalledBody(_ name: String) -> String {
        String(localized: "The widget controls \(name), which was not found on this Mac.")
    }
    static func notInstalledBodyWithLink(_ name: String) -> String {
        String(localized: "The widget controls the official \(name) app, which was not found on this Mac. Open the installation page?")
    }
    static var openInstallPage: String { String(localized: "Open installation page") }
    static var cancel: String { String(localized: "Cancel") }
    static var ok: String { String(localized: "OK") }
}
