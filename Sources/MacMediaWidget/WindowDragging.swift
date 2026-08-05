import AppKit
import SwiftUI

/// NSView invisível cuja única função é marcar a região que ocupa como
/// NÃO-movível.
///
/// Com `isMovableByWindowBackground` ligado na janela, o AppKit faz `hitTest`
/// no `contentView` no `mouseDown` e pergunta à view resultante se ela permite
/// arrastar a janela. Como o SwiftUI desenha `Text`/`Image`/`Button` em camadas
/// — e não em NSViews —, o `hitTest` sempre devolvia o `NSHostingView` inteiro,
/// que responde `true`: o card todo virava alça de arrasto, inclusive por cima
/// dos botões de transporte. `mouseDownCanMoveWindow` é propriedade da view, não
/// função da posição do clique, então granularidade por área só se obtém
/// inserindo uma NSView real na área. É o mesmo motivo pelo qual o `NSSlider` de
/// volume já não arrastava a janela (`NSControl` responde `false` de fábrica).
final class NonDraggableNSView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }

    /// A janela é uma `NSPanel` não-ativante: sem isto, o primeiro clique com o
    /// widget não-key seria consumido apenas para torná-lo key, exigindo dois
    /// cliques para acionar um botão.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override var isOpaque: Bool { false }

    // Nada de `mouseDown` aqui: o default do NSResponder repassa o evento ao
    // `nextResponder` (o `NSHostingView`), que é quem entrega o clique ao
    // SwiftUI. Sobrescrever engoliria o clique do botão.
}

struct NonDraggableArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NonDraggableNSView { NonDraggableNSView() }
    func updateNSView(_ nsView: NonDraggableNSView, context: Context) {}
}

extension View {
    /// Impede que arrastar nesta área mova a janela.
    ///
    /// Vai em `.background` e nunca em `.overlay`: abaixo do conteúdo, o
    /// hit-test do SwiftUI continua entregando o clique ao controle, enquanto o
    /// hit-test do AppKit encontra esta NSView e recusa o arrasto. Em `.overlay`
    /// a view taparia o controle — e corrigir isso com `.allowsHitTesting(false)`
    /// desligaria a própria proteção.
    func nonDraggableWindowArea() -> some View {
        background { NonDraggableArea() }
    }
}
