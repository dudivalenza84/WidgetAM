import AppKit
import SwiftUI

/// Constrói o menu do app — o mesmo conteúdo para a bandeja e para o clique direito no
/// widget, montado num lugar só para os dois nunca divergirem.
///
/// O estado exibido (nome do player preferido, checkmark do login, submenu de players)
/// muda em runtime, então o menu é repopulado a cada abertura: a bandeja via
/// `menuWillOpen`, e o menu de contexto por já nascer populado a cada clique.
@MainActor
final class AppMenuController: NSObject, NSMenuDelegate {
    /// Largura das views custom (status e transporte). Como o resto dos itens é texto
    /// curto, é ela quem dita a largura do menu — padronizada, independente do nome da
    /// música (que rola em letreiro na `MenuStatusView` quando não cabe).
    private static let contentWidth: CGFloat = 220

    /// Auto-fechamento do menu da bandeja: fecha após este tempo sem interação, desde
    /// que o mouse não esteja sobre o menu. Só vale para a bandeja — o menu de
    /// contexto do widget se comporta como menu normal.
    private static let autoCloseDelay: TimeInterval = 2.0
    private static let autoCloseTickInterval: TimeInterval = 0.25

    private let nowPlaying: NowPlayingController
    private let onToggleWidget: () -> Void
    private let onOpenPreferredPlayer: () -> Void
    private let onOpenPreferences: () -> Void
    private let onQuit: () -> Void

    private weak var statusMenu: NSMenu?
    private var autoCloseTimer: Timer?
    private var idleTime: TimeInterval = 0

    init(
        nowPlaying: NowPlayingController,
        onToggleWidget: @escaping () -> Void,
        onOpenPreferredPlayer: @escaping () -> Void,
        onOpenPreferences: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.nowPlaying = nowPlaying
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
        statusMenu = menu
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
        if menu === statusMenu {
            startAutoCloseWatch()
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        if menu === statusMenu {
            stopAutoCloseWatch()
        }
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
        menu.addItem(playbackStatusItem())
        menu.addItem(transportItem())
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

    /// Linha informativa com o estado do player e a faixa atual, numa view custom de
    /// largura fixa: nome longo rola em letreiro em vez de esticar o menu. A view
    /// observa o `NowPlayingController`, então atualiza ao vivo com o menu aberto.
    private func playbackStatusItem() -> NSMenuItem {
        let item = NSMenuItem()
        // A largura vai como parâmetro da view, não só no frame do hosting: dentro de
        // menu o NSHostingView faz o layout pelo tamanho ideal do conteúdo, e sem a
        // largura explícita o letreiro nunca enxergaria overflow.
        let hosting = NSHostingView(
            rootView: MenuStatusView(nowPlaying: nowPlaying, width: Self.contentWidth)
        )
        hosting.frame = NSRect(x: 0, y: 0, width: Self.contentWidth, height: 24)
        item.view = hosting
        return item
    }

    /// Linha com os três botões de transporte lado a lado. View custom não fecha o
    /// menu ao clicar — dá para pausar e pular faixas em sequência.
    private func transportItem() -> NSMenuItem {
        let item = NSMenuItem()
        let hosting = NSHostingView(rootView: MenuTransportView(nowPlaying: nowPlaying))
        hosting.frame = NSRect(x: 0, y: 0, width: Self.contentWidth, height: 32)
        hosting.autoresizingMask = [.width]
        item.view = hosting
        return item
    }

    // MARK: - Auto-fechamento do menu da bandeja

    /// O menu é modal (tracking loop próprio), então o relógio é um `Timer` em modo
    /// `.common` — dispara mesmo durante o tracking. A cada tick: mouse sobre a janela
    /// do menu ou item destacado (inclui submenu aberto e navegação por teclado) zera
    /// a contagem; caso contrário ela acumula e, em `autoCloseDelay`, o menu fecha via
    /// `cancelTracking()`.
    private func startAutoCloseWatch() {
        stopAutoCloseWatch()
        idleTime = 0
        let timer = Timer(timeInterval: Self.autoCloseTickInterval, repeats: true) { [weak self] _ in
            // O timer vive no RunLoop.main; o pulo de isolamento é só formal.
            MainActor.assumeIsolated { self?.autoCloseTick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        autoCloseTimer = timer
    }

    private func stopAutoCloseWatch() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
    }

    private func autoCloseTick() {
        guard let menu = statusMenu else {
            stopAutoCloseWatch()
            return
        }
        if menu.highlightedItem != nil || mouseIsOver(menu) {
            idleTime = 0
            return
        }
        idleTime += Self.autoCloseTickInterval
        if idleTime >= Self.autoCloseDelay {
            stopAutoCloseWatch()
            menu.cancelTracking()
        }
    }

    /// A janela do painel do menu não é exposta pelo `NSMenu`; o caminho até ela é a
    /// `window` de qualquer item com view custom (status e transporte sempre existem).
    private func mouseIsOver(_ menu: NSMenu) -> Bool {
        guard let window = menu.items.first(where: { $0.view != nil })?.view?.window else {
            return false
        }
        return window.frame.contains(NSEvent.mouseLocation)
    }

    /// Submenu "Trocar app": um item por player conhecido instalado, com checkmark no
    /// preferido atual. Escolher troca a preferência **e abre o app** — decisão do
    /// dono do produto (sessão 2026-08-11 · #01): trocar sem abrir deixaria a ação
    /// sem efeito visível no modo automático com outro app tocando.
    private func switchAppItem() -> NSMenuItem {
        let submenu = NSMenu()
        let preferredId = AppSettings.shared.preferredPlayerBundleId
        for player in PlayerRegistry.shared.installedCatalogPlayers() {
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
