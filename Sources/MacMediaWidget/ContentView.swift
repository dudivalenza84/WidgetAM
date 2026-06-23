import AppKit
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
    @ObservedObject private var settings = AppSettings.shared
    @StateObject private var volume = SystemVolumeController()
    @State private var tint: Color = .clear

    private var track: TrackInfo { nowPlaying.track }

    var body: some View {
        HStack(spacing: 12) {
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
            volumeSidebar
        }
        .padding(16)
        .frame(width: WidgetMetrics.width, height: WidgetMetrics.height)
        .modifier(CardSurface(tint: tint, tintOpacity: settings.tintOpacity))
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
                nowPlaying.playPauseEnsuringApp()
            }
            button("forward.fill", size: 15) { nowPlaying.send(.nextTrack) }
        }
        .foregroundStyle(.primary)
    }

    /// Sidebar de volume fixa, na lateral direita do card: slider vertical com o
    /// botão de mute abaixo. Controla o volume de saída do sistema (global) — ver
    /// `SystemVolumeController`.
    private var volumeSidebar: some View {
        VStack(spacing: 8) {
            VerticalVolumeSlider(value: volume.volume) { volume.setVolume($0) }
                .frame(width: 20, height: 84)

            Button { volume.toggleMute() } label: {
                Image(systemName: speakerSymbol)
                    .font(.system(size: 12, weight: .medium))
                    .frame(height: 14)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.secondary)
        .frame(width: 24)
    }

    private var speakerSymbol: String {
        if volume.isMuted || volume.volume == 0 { return "speaker.slash.fill" }
        switch volume.volume {
        case ..<0.33: return "speaker.wave.1.fill"
        case ..<0.66: return "speaker.wave.2.fill"
        default: return "speaker.wave.3.fill"
        }
    }

    private func button(_ systemName: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName).font(.system(size: size, weight: .medium))
        }
        .buttonStyle(.plain)
    }
}

/// Superfície do card. No macOS 26 usa o `glassEffect` nativo (Liquid Glass)
/// tonalizado pela cor da capa; em versões anteriores cai para `.ultraThinMaterial`
/// com overlay de cor, o visual da base anterior.
private struct CardSurface: ViewModifier {
    let tint: Color
    let tintOpacity: Double

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: WidgetMetrics.cornerRadius, style: .continuous)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            // O vidro vai numa camada de fundo, não sobre o conteúdo: aplicar
            // `glassEffect` diretamente na stack faz o macOS tratar o card inteiro
            // como superfície de vidro que captura o arraste, roubando o clique do
            // NSSlider de volume e movendo a janela.
            content
                .background {
                    Color.clear.glassEffect(.regular.tint(tint.opacity(tintOpacity)), in: shape)
                }
                .clipShape(shape)
        } else {
            content
                .background(
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        tint.opacity(tintOpacity)
                    }
                )
                .clipShape(shape)
        }
    }
}

/// `NSSlider` vertical nativo. Usado em vez de um `Slider` SwiftUI rotacionado:
/// a rotação desloca a área de hit-test, fazendo o clique cair no "fundo" da
/// janela (que é movível) em vez de no controle. O `NSSlider` mantém o
/// hit-testing correto e marca sua área como não-movível.
struct VerticalVolumeSlider: NSViewRepresentable {
    var value: Double
    var onChange: (Double) -> Void

    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider(
            value: value, minValue: 0, maxValue: 1,
            target: context.coordinator,
            action: #selector(Coordinator.changed(_:))
        )
        slider.isVertical = true
        slider.controlSize = .mini
        return slider
    }

    func updateNSView(_ slider: NSSlider, context: Context) {
        context.coordinator.onChange = onChange
        if slider.doubleValue != value { slider.doubleValue = value }
    }

    func makeCoordinator() -> Coordinator { Coordinator(onChange: onChange) }

    final class Coordinator {
        var onChange: (Double) -> Void
        init(onChange: @escaping (Double) -> Void) { self.onChange = onChange }
        @objc func changed(_ sender: NSSlider) { onChange(sender.doubleValue) }
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
