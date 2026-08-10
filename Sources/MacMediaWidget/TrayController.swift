import AppKit

/// Ícone na barra de menu (NSStatusItem) com ações básicas: mostrar/ocultar o
/// widget, abrir o player preferido, alternar o autostart no login e sair.
@MainActor
final class TrayController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let preferredPlayerName: () -> String?
    private let onToggleWidget: () -> Void
    private let onOpenPreferredPlayer: () -> Void
    private let onOpenPreferences: () -> Void
    private let onQuit: () -> Void

    private var loginItemMenuItem: NSMenuItem!
    private var openPlayerMenuItem: NSMenuItem!

    init(
        preferredPlayerName: @escaping () -> String?,
        onToggleWidget: @escaping () -> Void,
        onOpenPreferredPlayer: @escaping () -> Void,
        onOpenPreferences: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.preferredPlayerName = preferredPlayerName
        self.onToggleWidget = onToggleWidget
        self.onOpenPreferredPlayer = onOpenPreferredPlayer
        self.onOpenPreferences = onOpenPreferences
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
        openPlayerMenuItem = menuItem("Abrir player", #selector(openPreferredPlayer))
        menu.addItem(openPlayerMenuItem)
        menu.addItem(.separator())
        menu.addItem(menuItem("Preferências…", #selector(openPreferences)))
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

    /// Mantém o checkmark do autostart e o nome do player em sincronia ao abrir o menu.
    /// O player preferido é preferência do usuário e muda em runtime, então o título
    /// não pode ser fixado na construção do menu.
    func menuWillOpen(_ menu: NSMenu) {
        loginItemMenuItem.state = LoginItem.isEnabled ? .on : .off
        openPlayerMenuItem.title = preferredPlayerName().map { "Abrir \($0)" } ?? "Abrir player"
    }

    @objc private func toggleWidget() { onToggleWidget() }
    @objc private func openPreferredPlayer() { onOpenPreferredPlayer() }
    @objc private func openPreferences() { onOpenPreferences() }
    @objc private func quit() { onQuit() }

    @objc private func toggleLoginItem() {
        let enabled = LoginItem.toggle()
        loginItemMenuItem.state = enabled ? .on : .off
    }
}
