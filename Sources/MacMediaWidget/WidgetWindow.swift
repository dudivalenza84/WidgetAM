import AppKit
import SwiftUI

/// Janela do widget de mesa: sem bordas, translúcida, em nível de mesa (atrás
/// das janelas, como os widgets nativos), presente em todos os Spaces e
/// não-ativante (não rouba foco). Ao ser arrastada, alinha-se a uma grade e
/// persiste a posição em UserDefaults.
@MainActor
final class WidgetWindow: NSPanel, NSWindowDelegate {
    /// Distância da borda da tela até a borda visível do card, em pontos.
    /// Calibrada para o widget assentar na mesma coluna dos widgets nativos.
    private let edgeMargin: CGFloat = 16
    /// Passo fino para alinhamento vertical (ajuste de altura livre).
    private let gridStepY: CGFloat = 8
    private let originDefaultsKey = "widgetOrigin"

    private var snapTimer: Timer?

    init(nowPlaying: NowPlayingController) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: WidgetMetrics.windowWidth, height: WidgetMetrics.windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        // Nível de mesa: acima dos ícones do desktop, atrás das janelas comuns.
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        isOpaque = false
        backgroundColor = .clear
        // A sombra fica a cargo do SwiftUI (acompanha o card arredondado). A
        // sombra da NSWindow seria retangular e vazaria nos cantos.
        hasShadow = false
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        // Necessário para o hover (slider de volume) funcionar mesmo com a janela
        // não-key/não-ativante.
        acceptsMouseMovedEvents = true
        delegate = self

        let host = NSHostingView(rootView: ContentView(nowPlaying: nowPlaying))
        host.autoresizingMask = [.width, .height]
        contentView = host
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func showWidget() {
        if let saved = savedOrigin() {
            setFrameOrigin(saved)
        } else {
            center()
        }
        orderFrontRegardless()
    }

    func toggleVisibility() {
        if isVisible {
            orderOut(nil)
        } else {
            orderFrontRegardless()
        }
    }

    // MARK: - Snap à grade + persistência

    /// Durante o arraste, `windowDidMove` dispara repetidamente. Fazemos debounce:
    /// só alinhamos e salvamos quando o movimento para.
    func windowDidMove(_ notification: Notification) {
        snapTimer?.invalidate()
        snapTimer = Timer(timeInterval: 0.2, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.snapToGrid() }
        }
        if let snapTimer { RunLoop.main.add(snapTimer, forMode: .common) }
    }

    private func snapToGrid() {
        guard let screen = screen ?? NSScreen.main else { return }
        let sf = screen.frame
        let margin = WidgetMetrics.shadowMargin // borda transparente da janela
        let origin = frame.origin

        // Horizontal: ancora à borda da tela mais próxima do centro do card, de
        // modo que a borda VISÍVEL do card fique a `edgeMargin` da borda da tela.
        let cardCenterX = frame.midX
        let snappedX: CGFloat
        if cardCenterX > sf.midX {
            // Ancora à direita.
            snappedX = sf.maxX - edgeMargin + margin - frame.width
        } else {
            // Ancora à esquerda.
            snappedX = sf.minX + edgeMargin - margin
        }

        // Vertical: grade fina, para ajuste de altura livre.
        let snappedY = (origin.y / gridStepY).rounded() * gridStepY

        let snapped = NSPoint(x: snappedX, y: snappedY)
        if snapped != origin {
            setFrameOrigin(snapped)
        }
        UserDefaults.standard.set(NSStringFromPoint(snapped), forKey: originDefaultsKey)
    }

    private func savedOrigin() -> NSPoint? {
        guard let raw = UserDefaults.standard.string(forKey: originDefaultsKey) else { return nil }
        let point = NSPointFromString(raw)
        return point == .zero ? nil : point
    }
}
