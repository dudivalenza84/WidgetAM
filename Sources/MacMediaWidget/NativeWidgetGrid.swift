import AppKit

/// Grade de células dos widgets nativos da mesa (Central de Notificações),
/// medida empiricamente em 2026-08-09: células de 180×180 pt sem gutter externo
/// (o respiro entre cards é o inset interno de ~5 pt de cada um; um widget
/// *medium* ocupa exatamente 2 células, 360×180). A âncora real é lida ao vivo
/// das janelas dos widgets nativos via CGWindowList; sem nenhum widget nativo
/// na mesa, cai na âncora replicada da geometria padrão: coluna terminando a
/// 8 pt da borda direita da tela e primeira linha 28 pt abaixo da menu bar
/// (ambos conferidos contra widgets nativos reais em 2026-08-09).
enum NativeWidgetGrid {
    /// Lado da célula da grade (janela de um widget small).
    static let pitch: CGFloat = 180
    /// Inset entre a borda da célula e o card visível do widget.
    static let cardInset: CGFloat = 5
    /// Nível de janela dos widgets nativos da mesa (desktopIcon + 2).
    static var nativeLevel: Int { Int(CGWindowLevelForKey(.desktopIconWindow)) + 2 }

    /// Âncora da grade em coordenadas Cocoa: `x` é a borda esquerda de uma
    /// célula qualquer; `topY` é a borda superior de uma linha qualquer. As
    /// demais bordas saem por deslocamentos inteiros de `pitch`.
    struct Anchor {
        let x: CGFloat
        let topY: CGFloat
    }

    static func anchor(for screen: NSScreen) -> Anchor {
        if let measured = measuredAnchor() { return measured }
        let sf = screen.frame
        return Anchor(x: sf.maxX - 8 - pitch, topY: screen.visibleFrame.maxY - 28)
    }

    /// Procura uma janela de widget nativo (nível e tamanho característicos) e
    /// converte a posição dela em âncora. Tamanhos de widget são múltiplos
    /// exatos da célula — o filtro descarta o chrome de hover da Central de
    /// Notificações, que vive em outro nível e com tamanho quebrado.
    private static func measuredAnchor() -> Anchor? {
        guard let mainHeight = NSScreen.screens.first?.frame.height,
              let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
                as? [[String: Any]] else { return nil }

        for entry in list {
            guard let layer = entry["kCGWindowLayer"] as? Int, layer == nativeLevel,
                  let bounds = entry["kCGWindowBounds"] as? [String: Any],
                  let x = bounds["X"] as? Double, let y = bounds["Y"] as? Double,
                  let width = bounds["Width"] as? Double, let height = bounds["Height"] as? Double,
                  width >= Double(pitch), height >= Double(pitch),
                  width.truncatingRemainder(dividingBy: Double(pitch)) == 0,
                  height.truncatingRemainder(dividingBy: Double(pitch)) == 0
            else { continue }
            // CGWindow tem origem no canto superior esquerdo; Cocoa, no inferior.
            return Anchor(x: CGFloat(x), topY: mainHeight - CGFloat(y))
        }
        return nil
    }

    /// Alinha um valor à malha ancorada em `origin` com passo `pitch`.
    static func snap(_ value: CGFloat, to origin: CGFloat) -> CGFloat {
        origin + ((value - origin) / pitch).rounded() * pitch
    }
}
