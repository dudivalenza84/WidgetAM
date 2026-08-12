import AppKit

/// Ícone na barra de menu (NSStatusItem). O conteúdo do menu vem inteiro do
/// `AppMenuController` — o mesmo que alimenta o clique direito no widget.
@MainActor
final class TrayController {
    private let statusItem: NSStatusItem

    init(menu: NSMenu) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = Self.icon()
        }
        statusItem.menu = menu
    }

    /// Glifo da marca (anel de progresso + play, `Resources/icon/`), como template —
    /// o AppKit recolore conforme o fundo da barra. Rodando o binário solto do SPM não
    /// há bundle montado, e o fallback é o SF Symbol antigo.
    private static func icon() -> NSImage? {
        if let path = Bundle.main.path(forResource: "MenuBarIcon", ofType: "png"),
           let image = NSImage(contentsOfFile: path) {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = true
            image.accessibilityDescription = "MacMediaWidget"
            return image
        }
        return NSImage(
            systemSymbolName: "music.note.list",
            accessibilityDescription: "MacMediaWidget"
        )
    }
}
