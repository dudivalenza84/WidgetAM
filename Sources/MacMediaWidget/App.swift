import AppKit

// Ponto de entrada do app. Rodamos como "accessory" (sem ícone no Dock),
// equivalente em runtime ao LSUIElement do Info.plist — garante o comportamento
// mesmo quando executado fora do bundle .app durante o desenvolvimento.
@main
enum App {
    static func main() {
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
    private let nowPlaying = NowPlayingController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        widgetWindow = WidgetWindow(nowPlaying: nowPlaying)
        widgetWindow.showWidget()

        tray = TrayController(
            onToggleWidget: { [weak self] in self?.widgetWindow.toggleVisibility() },
            onOpenAmazonMusic: { NowPlayingController.openAmazonMusic() },
            onQuit: { NSApp.terminate(nil) }
        )

        nowPlaying.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        nowPlaying.stop()
    }
}
