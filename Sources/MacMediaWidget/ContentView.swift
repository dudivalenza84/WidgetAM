import SwiftUI

/// Dimensões do card, espelhando a proporção do widget de música nativo do macOS.
enum WidgetMetrics {
    static let width: CGFloat = 340
    static let height: CGFloat = 140
    static let cornerRadius: CGFloat = 24
    /// Margem transparente ao redor do card, onde a sombra do SwiftUI é desenhada.
    static let shadowMargin: CGFloat = 18

    static var windowWidth: CGFloat { width + shadowMargin * 2 }
    static var windowHeight: CGFloat { height + shadowMargin * 2 }
}

/// UI do widget no padrão dos widgets nativos do macOS: card de cantos bem
/// arredondados, fundo translúcido tonalizado pela cor dominante da capa, capa
/// com sombra, controles centralizados e barra de progresso animada.
struct ContentView: View {
    @ObservedObject var nowPlaying: NowPlayingController
    @State private var tint: Color = .clear

    private var track: TrackInfo { nowPlaying.track }

    var body: some View {
        HStack(spacing: 14) {
            artwork
            VStack(alignment: .leading, spacing: 6) {
                Text(track.title ?? "Nada tocando")
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                Text(track.artist ?? "—")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 2)
                progressBar
                controls
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .frame(width: WidgetMetrics.width, height: WidgetMetrics.height)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: WidgetMetrics.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
        .padding(WidgetMetrics.shadowMargin)
        .frame(width: WidgetMetrics.windowWidth, height: WidgetMetrics.windowHeight)
        .task(id: track.artwork) {
            if let color = track.artwork?.averageColor() {
                tint = Color(nsColor: color)
            } else {
                tint = .clear
            }
        }
    }

    // MARK: - Componentes

    private var cardBackground: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            tint.opacity(0.45)
        }
    }

    @ViewBuilder
    private var artwork: some View {
        Group {
            if let image = track.artwork {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quaternary)
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
    }

    private var progressBar: some View {
        let fraction: Double = {
            guard let dur = track.duration, dur > 0 else { return 0 }
            return min(max(nowPlaying.displayedElapsed / dur, 0), 1)
        }()
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.primary.opacity(0.18))
                Capsule().fill(.primary.opacity(0.7))
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 4)
        .animation(.linear(duration: 0.5), value: fraction)
    }

    private var controls: some View {
        HStack(spacing: 26) {
            button("backward.fill", size: 15) { nowPlaying.send(.previousTrack) }
            button(track.isPlaying ? "pause.fill" : "play.fill", size: 18) {
                nowPlaying.send(.togglePlayPause)
            }
            button("forward.fill", size: 15) { nowPlaying.send(.nextTrack) }
        }
        .foregroundStyle(.primary)
    }

    private func button(_ systemName: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName).font(.system(size: size, weight: .medium))
        }
        .buttonStyle(.plain)
    }
}

extension NSImage {
    /// Cor média da imagem (capa), usada como tonalização do card. Reduz a
    /// imagem a 1×1 e lê o pixel resultante.
    func averageColor() -> NSColor? {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: 1,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 4, bitsPerPixel: 32
        ) else { return nil }

        guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        ctx.imageInterpolation = .high
        draw(in: NSRect(x: 0, y: 0, width: 1, height: 1),
             from: .zero, operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        guard let data = rep.bitmapData else { return nil }
        return NSColor(
            red: CGFloat(data[0]) / 255.0,
            green: CGFloat(data[1]) / 255.0,
            blue: CGFloat(data[2]) / 255.0,
            alpha: 1.0
        )
    }
}
