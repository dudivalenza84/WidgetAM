import AppKit

/// Ícone na barra de menu (NSStatusItem). O conteúdo do menu vem inteiro do
/// `AppMenuController` — o mesmo que alimenta o clique direito no widget.
@MainActor
final class TrayController {
    private let statusItem: NSStatusItem

    init(menu: NSMenu) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "music.note.list",
                accessibilityDescription: "MacMediaWidget"
            )
        }
        statusItem.menu = menu
    }
}
