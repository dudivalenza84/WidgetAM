import AppKit

// Ponto de entrada do app. Rodamos como "accessory" (sem ícone no Dock),
// equivalente em runtime ao LSUIElement do Info.plist — garante o comportamento
// mesmo quando executado fora do bundle .app durante o desenvolvimento.
@main
enum App {
    static func main() {
        // `swift run MacMediaWidget --run-tests` roda a suíte e sai, sem abrir janela.
        // Só existe em debug — ver SelfTests.swift para o porquê de não ser um testTarget.
        #if DEBUG
        if CommandLine.arguments.contains("--run-tests") {
            exit(MainActor.assumeIsolated { SelfTests.run() })
        }
        #endif

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var widgetWindow: WidgetWindow!
    private var tray: TrayController!
    private var menuController: AppMenuController!
    private var hotKey: GlobalHotKey?
    private let preferences = PreferencesController()
    private let nowPlaying = NowPlayingController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        widgetWindow = WidgetWindow(nowPlaying: nowPlaying)

        // Um só construtor de menu para a bandeja e para o clique direito no widget.
        menuController = AppMenuController(
            nowPlaying: nowPlaying,
            onToggleWidget: { [weak self] in self?.widgetWindow.toggleVisibility() },
            onOpenPreferredPlayer: { [weak self] in self?.nowPlaying.preferredPlayer.launch() },
            onOpenPreferences: { [weak self] in self?.preferences.show() },
            onQuit: { NSApp.terminate(nil) }
        )
        widgetWindow.contextMenuProvider = { [weak self] in
            self?.menuController.makeContextMenu() ?? NSMenu()
        }
        widgetWindow.showWidget()

        tray = TrayController(menu: menuController.makeStatusMenu())

        // ⌃⌥⌘M traz o widget à frente para ser operado (e devolve no segundo aperto).
        hotKey = GlobalHotKey { [weak self] in self?.widgetWindow.bringToFront() }

        nowPlaying.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        nowPlaying.stop()
    }
}
