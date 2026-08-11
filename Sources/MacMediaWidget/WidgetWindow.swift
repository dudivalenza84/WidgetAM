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

    /// Fábrica do menu de contexto (clique direito). Injetada pelo AppDelegate para a
    /// janela não conhecer o `AppMenuController`.
    var contextMenuProvider: (() -> NSMenu)?

    /// Elevado temporariamente pelo atalho global: fica sobre as janelas comuns até o
    /// próximo aperto do atalho (ou até perder o estado de key), sem mexer na
    /// preferência persistida `keepAbove`.
    private var isTemporarilyRaised = false

    init(nowPlaying: NowPlayingController) {
        self.nowPlaying = nowPlaying
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: WidgetMetrics.windowWidth, height: WidgetMetrics.windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
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
        applyLevel()

        let host = NSHostingView(rootView: ContentView(nowPlaying: nowPlaying))
        host.autoresizingMask = [.width, .height]
        contentView = host

        // Aplica ao vivo a troca de "manter sobre as demais janelas" nas preferências.
        // O Task adia para depois do didSet: @Published emite no willSet, quando
        // `settings.keepAbove` ainda tem o valor antigo.
        settings.$keepAbove
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in self?.applyLevel() }
            }
            .store(in: &cancellables)

        // Realinha ao vivo quando o snap é ligado nas preferências (ignora a
        // emissão do valor inicial com dropFirst).
        settings.$snapToGrid
            .dropFirst()
            .sink { [weak self] enabled in
                guard enabled else { return }
                Task { @MainActor in self?.snapToGrid() }
            }
            .store(in: &cancellables)

        // Monitor desconectado, resolução trocada, Mac que dormiu acoplado e acordou
        // sozinho: a posição atual pode deixar de existir enquanto o app roda. Sem isto
        // o widget fica fora de qualquer tela e não há como resgatá-lo — ele não tem
        // ícone no Dock, e a bandeja só oculta e mostra no mesmo lugar invisível.
        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                Task { @MainActor in self?.recoverIfOffscreen() }
            }
            .store(in: &cancellables)
    }

    /// Traz o widget de volta se a configuração de telas mudou e ele ficou fora.
    private func recoverIfOffscreen() {
        guard !Self.isOnSomeScreen(origin: frame.origin, size: frame.size) else {
            // Ainda visível, mas a grade pode ter mudado de lugar com a resolução.
            snapToGrid()
            return
        }
        center()
        snapToGrid()
        NSLog("MacMediaWidget: telas mudaram e o widget ficou fora; recentralizado")
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // MARK: - Nível de janela

    /// Nível conforme o estado: em nível de mesa (como os widgets nativos) por padrão;
    /// flutuando sobre as janelas comuns com a preferência `keepAbove` ligada ou
    /// enquanto elevado pelo atalho global.
    private func applyLevel() {
        if settings.keepAbove || isTemporarilyRaised {
            level = .floating
        } else {
            // Mesmo nível dos widgets nativos da mesa (medido via CGWindowList):
            // acima dos ícones do desktop, atrás das janelas comuns.
            level = NSWindow.Level(rawValue: NativeWidgetGrid.nativeLevel)
        }
    }

    /// Ação do atalho global: mostra o widget se escondido e o eleva sobre as janelas
    /// comuns para ser operado. Um segundo aperto (ou perder o estado de key) devolve
    /// ao nível de mesa — a menos que a preferência `keepAbove` já o mantenha em cima.
    func bringToFront() {
        if !isVisible {
            showWidget()
        } else if isTemporarilyRaised {
            isTemporarilyRaised = false
            applyLevel()
            return
        }
        isTemporarilyRaised = true
        applyLevel()
        orderFrontRegardless()
    }

    /// Interagir com o widget elevado pode torná-lo key; clicar em outro app depois
    /// desfaz a elevação temporária — o atalho serve para uma operação pontual, não
    /// para deixar o widget preso na frente sem o usuário pedir.
    func windowDidResignKey(_ notification: Notification) {
        guard isTemporarilyRaised else { return }
        isTemporarilyRaised = false
        applyLevel()
    }

    // MARK: - Mouse

    /// Duplo clique em área "morta" do card (fundo, capa, textos) abre o player que o
    /// widget está exibindo. Cliques sobre controles não chegam aqui: botões, slider e
    /// barra de seek consomem o evento antes de ele subir à janela.
    override func mouseUp(with event: NSEvent) {
        if event.clickCount == 2 {
            nowPlaying.openSourcePlayer()
            return
        }
        super.mouseUp(with: event)
    }

    /// Clique direito em qualquer ponto do card abre o mesmo menu da bandeja. O evento
    /// chega aqui pela responder chain: o NSHostingView não tem menu de contexto
    /// próprio e repassa.
    override func rightMouseDown(with event: NSEvent) {
        guard let menu = contextMenuProvider?(), let contentView else {
            super.rightMouseDown(with: event)
            return
        }
        NSMenu.popUpContextMenu(menu, with: event, for: contentView)
    }

    func showWidget() {
        if let saved = savedOrigin(), Self.isOnSomeScreen(origin: saved, size: frame.size) {
            setFrameOrigin(saved)
        } else {
            // Sem posição salva — ou com uma que não existe mais. A segunda situação é
            // o monitor externo desconectado, a resolução trocada, o Mac que dormiu
            // acoplado e acordou sozinho: restaurar a posição às cegas colocaria o
            // widget fora de qualquer tela, invisível e sem como resgatar (ele não tem
            // ícone no Dock, e mostrar/ocultar pela bandeja não o traz de volta).
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

    /// A janela, nessa posição, apareceria em alguma tela conectada agora?
    ///
    /// Exige interseção com folga de meio card: encostar um canto de 1 pt numa tela
    /// conta como "visível" para o AppKit, mas para o usuário é um widget sumido.
    /// `screenFrames` é injetável para poder ser exercitado sem depender do monitor
    /// que estiver plugado na máquina de quem roda os testes.
    static func isOnSomeScreen(
        origin: NSPoint,
        size: NSSize,
        screenFrames: [NSRect]? = nil
    ) -> Bool {
        let frames = screenFrames ?? NSScreen.screens.map(\.frame)
        let frame = NSRect(origin: origin, size: size)
        let minimoVisivel = NSSize(width: size.width / 2, height: size.height / 2)
        return frames.contains { screenFrame in
            let interseção = screenFrame.intersection(frame)
            return interseção.width >= minimoVisivel.width
                && interseção.height >= minimoVisivel.height
        }
    }
}
