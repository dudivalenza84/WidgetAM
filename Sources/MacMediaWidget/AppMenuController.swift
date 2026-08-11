import AppKit

/// Constrói o menu do app — o mesmo conteúdo para a bandeja e para o clique direito no
/// widget, montado num lugar só para os dois nunca divergirem.
///
/// O estado exibido (nome do player preferido, checkmark do login, submenu de players)
/// muda em runtime, então o menu é repopulado a cada abertura: a bandeja via
/// `menuWillOpen`, e o menu de contexto por já nascer populado a cada clique.
@MainActor
final class AppMenuController: NSObject, NSMenuDelegate {
    private let onToggleWidget: () -> Void
    private let onOpenPreferredPlayer: () -> Void
    private let onOpenPreferences: () -> Void
    private let onQuit: () -> Void

    init(
        onToggleWidget: @escaping () -> Void,
        onOpenPreferredPlayer: @escaping () -> Void,
        onOpenPreferences: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onToggleWidget = onToggleWidget
        self.onOpenPreferredPlayer = onOpenPreferredPlayer
        self.onOpenPreferences = onOpenPreferences
        self.onQuit = onQuit
    }

    /// Menu persistente da bandeja: fica pendurado no `NSStatusItem` e se atualiza a
    /// cada abertura via delegate.
    func makeStatusMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        populate(menu)
        return menu
    }

    /// Menu de contexto do widget: instância nova por clique, já com o estado atual.
    /// Não reaproveita o menu da bandeja — um NSMenu não pode estar aberto em dois
    /// lugares, e o custo de montar é desprezível.
    func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        populate(menu)
        return menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        populate(menu)
    }

    private func populate(_ menu: NSMenu) {
        menu.removeAllItems()

        // Sem action, o autoenable desabilita sozinho: vira a linha informativa de
        // versão pedida pelo dono do produto.
        menu.addItem(NSMenuItem(
            title: "MacMediaWidget \(AppVersion.current)",
            action: nil,
            keyEquivalent: ""
        ))
        menu.addItem(.separator())

        menu.addItem(item(L10n.showHideWidget, #selector(toggleWidget)))
        let openTitle = preferredPlayer.map { L10n.openPlayer($0.displayName) }
            ?? L10n.openPlayerGeneric
        menu.addItem(item(openTitle, #selector(openPreferredPlayer)))
        menu.addItem(switchAppItem())
        menu.addItem(.separator())

        menu.addItem(item(L10n.preferences, #selector(openPreferences)))
        let login = item(L10n.openAtLogin, #selector(toggleLoginItem))
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())

        menu.addItem(item(L10n.quit, #selector(quit)))
    }

    /// Submenu "Trocar app": um item por player conhecido instalado, com checkmark no
    /// preferido atual. Escolher troca a preferência **e abre o app** — decisão do
    /// dono do produto (sessão 2026-08-11 · #01): trocar sem abrir deixaria a ação
    /// sem efeito visível no modo automático com outro app tocando.
    private func switchAppItem() -> NSMenuItem {
        let submenu = NSMenu()
        let preferredId = AppSettings.shared.preferredPlayerBundleId
        for player in PlayerRegistry.shared.installedKnownPlayers() {
            let entry = NSMenuItem(
                title: player.displayName,
                action: #selector(selectPlayer(_:)),
                keyEquivalent: ""
            )
            entry.target = self
            entry.representedObject = player.bundleIdentifier
            entry.state = player.bundleIdentifier == preferredId ? .on : .off
            if let icon = player.icon {
                let sized = icon.copy() as! NSImage
                sized.size = NSSize(width: 16, height: 16)
                entry.image = sized
            }
            submenu.addItem(entry)
        }

        let item = NSMenuItem(title: L10n.switchApp, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    private var preferredPlayer: Player? {
        PlayerRegistry.shared.player(for: AppSettings.shared.preferredPlayerBundleId)
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func toggleWidget() { onToggleWidget() }
    @objc private func openPreferredPlayer() { onOpenPreferredPlayer() }
    @objc private func openPreferences() { onOpenPreferences() }
    @objc private func quit() { onQuit() }

    @objc private func toggleLoginItem() {
        LoginItem.toggle()
    }

    @objc private func selectPlayer(_ sender: NSMenuItem) {
        guard let bundleId = sender.representedObject as? String else { return }
        AppSettings.shared.preferredPlayerBundleId = bundleId
        PlayerRegistry.shared.player(for: bundleId)?.launch()
    }
}
