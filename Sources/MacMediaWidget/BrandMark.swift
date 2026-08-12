import SwiftUI

/// Glifo da marca — anel de progresso interrompido com play — desenhado em vetor
/// nativo para usos dentro da UI: herda a cor do contexto (`foregroundStyle`) e escala
/// sem asset. A geometria espelha `Resources/icon/menubar-template.svg` (base 120):
/// anel r 42 / traço 12 com vão no topo-direita, play de 49,42 a 82,60.
struct BrandMark: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .trim(from: 0, to: 205.0 / 264.0)
                    .stroke(style: StrokeStyle(lineWidth: s * (12.0 / 120.0), lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(s * (18.0 / 120.0))
                PlayGlyph()
                    .frame(width: s * (33.0 / 120.0), height: s * (36.0 / 120.0))
                    .offset(x: s * (5.5 / 120.0))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Triângulo de play com a proporção do glifo (33×36 na base 120).
private struct PlayGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
