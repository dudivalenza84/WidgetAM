import AppKit

/// Ícone na barra de menu (NSStatusItem) com ações básicas: mostrar/ocultar o
/// widget, abrir o Amazon Music, alternar o autostart no login e sair.
@MainActor
final class TrayController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let onToggleWidget: () -> Void
    private let onOpenAmazonMusic: () -> Void
    private let onQuit: () -> Void

    private var loginItemMenuItem: NSMenuItem!

    init(
        onToggleWidget: @escaping () -> Void,
        onOpenAmazonMusic: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onToggleWidget = onToggleWidget
        self.onOpenAmazonMusic = onOpenAmazonMusic
        self.onQuit = onQuit
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "music.note.list",
                accessibilityDescription: "MacMediaWidget"
            )
        }

        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(menuItem("Mostrar/ocultar widget", #selector(toggleWidget)))
        menu.addItem(menuItem("Abrir Amazon Music", #selector(openAmazonMusic)))
        menu.addItem(.separator())
        loginItemMenuItem = menuItem("Abrir no login", #selector(toggleLoginItem))
        menu.addItem(loginItemMenuItem)
        menu.addItem(.separator())
        menu.addItem(menuItem("Sair", #selector(quit)))
        statusItem.menu = menu
    }

    private func menuItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    /// Mantém o checkmark do autostart em sincronia ao abrir o menu.
    func menuWillOpen(_ menu: NSMenu) {
        loginItemMenuItem.state = LoginItem.isEnabled ? .on : .off
    }

    @objc private func toggleWidget() { onToggleWidget() }
    @objc private func openAmazonMusic() { onOpenAmazonMusic() }
    @objc private func quit() { onQuit() }

    @objc private func toggleLoginItem() {
        let enabled = LoginItem.toggle()
        loginItemMenuItem.state = enabled ? .on : .off
    }
}
