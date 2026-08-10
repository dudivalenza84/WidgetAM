import AppKit
import Combine
import SwiftUI

/// Janela do widget de mesa: sem bordas, translúcida, em nível de mesa (atrás
/// das janelas, como os widgets nativos), presente em todos os Spaces e
/// não-ativante (não rouba foco). Ao ser arrastada, alinha-se à grade celular
/// dos widgets nativos (ver NativeWidgetGrid) e persiste a posição.
@MainActor
final class WidgetWindow: NSPanel, NSWindowDelegate {
    private let settings = AppSettings.shared
    private let nowPlaying: NowPlayingController
    private let originDefaultsKey = "widgetOrigin"

    private var snapTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(nowPlaying: NowPlayingController) {
        self.nowPlaying = nowPlaying
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: WidgetMetrics.windowWidth, height: WidgetMetrics.windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        // Mesmo nível de janela dos widgets nativos da mesa (medido via
        // CGWindowList): acima dos ícones do desktop, atrás das janelas comuns.
        level = NSWindow.Level(rawValue: NativeWidgetGrid.nativeLevel)
        isOpaque = false
        backgroundColor = .clear
        // A sombra fica a cargo do SwiftUI (acompanha o card arredondado). A
        // sombra da NSWindow seria retangular e vazaria nos cantos.
        hasShadow = false
        // Arrasto pelo fundo do card. As áreas de controle (transporte e sidebar
        // de volume) se excluem do arrasto marcando a própria região com
        // `NonDraggableArea` — ver WindowDragging.swift.
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        // Necessário para o hover (slider de volume) funcionar mesmo com a janela
        // não-key/não-ativante.
        acceptsMouseMovedEvents = true
        delegate = self

        let host = NSHostingView(rootView: ContentView(nowPlaying: nowPlaying))
        host.autoresizingMask = [.width, .height]
        contentView = host

        // Realinha ao vivo quando o snap é ligado nas preferências (ignora a
        // emissão do valor inicial com dropFirst).
        settings.$snapToGrid
            .dropFirst()
            .sink { [weak self] enabled in
                guard enabled else { return }
                Task { @MainActor in self?.snapToGrid() }
            }
            .store(in: &cancellables)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func showWidget() {
        if let saved = savedOrigin() {
            setFrameOrigin(saved)
        } else {
            center()
        }
        // Realinha à grade na exibição: posição salva por versão anterior (ou
        // por outra tela) pode estar fora das células.
        snapToGrid()
        orderFrontRegardless()
        nowPlaying.isWidgetVisible = true
    }

    func toggleVisibility() {
        if isVisible {
            orderOut(nil)
        } else {
            orderFrontRegardless()
        }
        // A leitura de posição real custa um subprocesso por segundo: não faz sentido
        // pagá-lo por uma barra que ninguém está vendo.
        nowPlaying.isWidgetVisible = isVisible
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
        // Snap desligado: o widget fica livre onde foi solto; só persiste a posição.
        guard settings.snapToGrid else {
            UserDefaults.standard.set(NSStringFromPoint(frame.origin), forKey: originDefaultsKey)
            return
        }

        guard let screen = screen ?? NSScreen.main else { return }
        let margin = WidgetMetrics.shadowMargin // borda transparente da janela
        let inset = NativeWidgetGrid.cardInset
        let anchor = NativeWidgetGrid.anchor(for: screen)

        // Footprint do card na grade nativa: as células que ele ocupa (o card
        // visível mais o inset interno padrão dos widgets). Alinhamos o canto
        // superior esquerdo do footprint à célula mais próxima nos dois eixos.
        let footprintLeft = frame.minX + margin - inset
        let footprintTop = frame.maxY - margin + inset
        let snappedLeft = NativeWidgetGrid.snap(footprintLeft, to: anchor.x)
        let snappedTop = NativeWidgetGrid.snap(footprintTop, to: anchor.topY)

        let snapped = NSPoint(
            x: snappedLeft + inset - margin,
            y: snappedTop - inset - WidgetMetrics.height - margin
        )
        if snapped != frame.origin {
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
