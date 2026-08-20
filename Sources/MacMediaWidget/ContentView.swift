import AppKit
import SwiftUI

/// Dimensões do card por formato, medidas na grade real da mesa (célula de
/// 180 pt, inset interno de 5 pt — ver NativeWidgetGrid): o card visível é o
/// footprint em células menos o inset de cada lado, como nos widgets nativos.
enum WidgetMetrics {
    static let cornerRadius: CGFloat = 24
    /// Margem transparente ao redor do card, onde a sombra do SwiftUI é desenhada.
    static let shadowMargin: CGFloat = 18

    static func cardSize(for size: WidgetSize) -> CGSize {
        let cell = NativeWidgetGrid.pitch - NativeWidgetGrid.cardInset * 2
        switch size {
        case .small: return CGSize(width: cell, height: cell)
        case .medium: return CGSize(width: cell + NativeWidgetGrid.pitch, height: cell)
        }
    }

    static func windowSize(for size: WidgetSize) -> CGSize {
        let card = cardSize(for: size)
        return CGSize(width: card.width + shadowMargin * 2, height: card.height + shadowMargin * 2)
    }
}

/// UI do widget no padrão dos widgets nativos do macOS: card de cantos bem
/// arredondados, fundo translúcido tonalizado pela cor dominante da capa, capa
/// com sombra, controles centralizados e barra de progresso animada.
struct ContentView: View {
    @ObservedObject var nowPlaying: NowPlayingController
    @ObservedObject private var settings = AppSettings.shared
    @StateObject private var volume = VolumeRouter()
    @State private var tint: Color = .clear
    /// Posição sob o dedo durante o arraste da barra; `nil` fora do gesto.
    @State private var dragFraction: Double?

    /// A faixa que o card mostra — não necessariamente a sessão de Now Playing: no modo
    /// fixo, com o player escolhido parado, o card fica vazio em vez de exibir o que
    /// outro app está tocando (ver `NowPlayingController.displayedTrack`).
    private var track: TrackInfo { nowPlaying.displayedTrack }

    private var isCompact: Bool { settings.widgetSize == .small }

    var body: some View {
        let card = WidgetMetrics.cardSize(for: settings.widgetSize)

        return Group {
            if isCompact {
                compactLayout
            } else {
                mediumLayout
            }
        }
        .padding(isCompact ? 14 : 16)
        .frame(width: card.width, height: card.height)
        .modifier(CardSurface(tint: tint, tintOpacity: settings.tintOpacity))
        // Marca-d'água discreta no canto: vive na calha do padding do card, então não
        // disputa espaço com nenhum layout. Sem hit test — o arraste passa através.
        .overlay(alignment: .bottomTrailing) {
            BrandMark()
                .frame(width: 11, height: 11)
                .opacity(0.16)
                .padding(5)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
        .padding(WidgetMetrics.shadowMargin)
        .frame(
            width: card.width + WidgetMetrics.shadowMargin * 2,
            height: card.height + WidgetMetrics.shadowMargin * 2
        )
        .task(id: track.artwork) {
            if let color = track.artwork?.averageColor() {
                tint = Color(nsColor: color)
            } else {
                tint = .clear
            }
        }
        // O alvo do volume acompanha o player controlado: trocar de fonte pode trocar
        // o volume do app pelo do sistema.
        .task(id: nowPlaying.controlledPlayer.bundleIdentifier) {
            volume.retarget(to: nowPlaying.controlledPlayer)
        }
    }

    // MARK: - Layouts

    /// Formato 2×1: capa grande à esquerda, textos/controles no centro, sidebar
    /// vertical de volume à direita. É o layout original do widget.
    private var mediumLayout: some View {
        HStack(spacing: 12) {
            artwork(side: 108, cornerRadius: 14)
            VStack(alignment: .leading, spacing: 6) {
                titleRow
                subtitleRow(size: 13)
                Spacer(minLength: 2)
                progressBar
                controls
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            volumeSidebar
        }
    }

    /// Formato 1×1: nos ~142 pt úteis do quadrado não cabe a sidebar vertical nem a
    /// capa grande — a capa encolhe para miniatura ao lado dos textos e o volume vira
    /// uma linha horizontal no rodapé. Os botões de transporte mantêm o mesmo alvo de
    /// clique do formato largo.
    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                artwork(side: 52, cornerRadius: 10)
                VStack(alignment: .leading, spacing: 2) {
                    titleRow
                    subtitleRow(size: 11)
                }
            }
            Spacer(minLength: 2)
            progressBar
            controls
                .frame(maxWidth: .infinity, alignment: .center)
            volumeFooter
        }
    }

    /// Título da faixa com o ícone da fonte ativa à direita — é como o widget diz de
    /// qual app ele está falando, agora que pode ser qualquer um.
    private var titleRow: some View {
        HStack(spacing: 6) {
            Text(hiddenSourceTitle ?? track.title ?? L10n.nothingPlaying)
                .font(.system(size: isCompact ? 12 : 16, weight: .bold))
                .lineLimit(isCompact ? 2 : 1)
            Spacer(minLength: 4)
            // O aviso de canal degradado toma o lugar do ícone da fonte: nesse estado
            // não há fonte confiável para identificar, e o alerta é o que importa.
            if let healthMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                    .help(healthMessage)
            } else if let icon = sourcePlayer?.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 15, height: 15)
                    .opacity(0.85)
                    .help(sourcePlayer?.displayName ?? "")
            }
        }
    }

    /// Player cuja identidade o card está exibindo.
    private var sourcePlayer: Player? {
        settings.controlMode == .fixed ? nowPlaying.controlledPlayer : nowPlaying.activePlayer
    }

    /// Aviso de que a sessão que toca é de um app que o usuário mandou ocultar.
    /// Precede o título da faixa porque, nesse estado, `displayedTrack` está vazio de
    /// propósito — sem o aviso o card diria "nada tocando" com música no ar.
    private var hiddenSourceTitle: String? {
        nowPlaying.hiddenSourceName.map(L10n.sourceHidden)
    }

    /// Segunda linha do card: o artista — ou, com a fonte oculta, a saída de volta.
    /// Card em branco com música tocando é indistinguível de app quebrado.
    @ViewBuilder
    private func subtitleRow(size: CGFloat) -> some View {
        if nowPlaying.hiddenSourceName != nil {
            Button(L10n.showThisApp) {
                if let id = nowPlaying.track.bundleIdentifier {
                    AppSettings.shared.setHidden(false, for: id)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .nonDraggableWindowArea()
        } else {
            Text(track.artist ?? subtitlePlaceholder)
                .font(.system(size: size))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    /// Sem faixa, a segunda linha explica o porquê em vez de mostrar um travessão mudo.
    private var subtitlePlaceholder: String {
        healthMessage ?? nowPlaying.transportUnavailableReason ?? L10n.noArtist
    }

    /// Aviso de canal degradado, quando há um. Precede qualquer outra explicação: se o
    /// widget está cego, dizer "nada tocando" seria mentira — ele não tem como saber.
    private var healthMessage: String? {
        switch nowPlaying.health {
        case .starting, .healthy:
            return nil
        case .reconnecting:
            return L10n.reconnecting
        case .unavailable(let reason):
            return reason
        }
    }

    // MARK: - Componentes

    private func artwork(side: CGFloat, cornerRadius: CGFloat) -> some View {
        Group {
            if let image = track.artwork {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: side * 0.28))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quaternary)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
    }

    /// A barra é indicador ou controle conforme a fonte: só vira arrastável onde o seek
    /// foi comprovado (`DECISOES.md · 2026-08-10 · #01`). No Amazon Music arrastar não
    /// faria nada — o app aceita o comando de posicionamento e o ignora —, então lá ela
    /// continua sendo só leitura.
    private var isSeekable: Bool {
        nowPlaying.canControlTransport
            && nowPlaying.controlledPlayer.capabilities.contains(.seek)
            && (track.duration ?? 0) > 0
    }

    private var progressBar: some View {
        let duration = track.duration ?? 0
        let playbackFraction: Double = {
            guard duration > 0 else { return 0 }
            return min(max(nowPlaying.displayedElapsed / duration, 0), 1)
        }()
        // Enquanto o dedo está na barra, quem manda é o dedo: esperar o eco do player
        // deixaria o preenchimento pulando para trás durante o arraste.
        let fraction = dragFraction ?? playbackFraction

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.primary.opacity(0.18))
                Capsule().fill(.primary.opacity(isSeekable && dragFraction != nil ? 0.9 : 0.7))
                    .frame(width: geo.size.width * fraction)
            }
            .frame(height: 4)
            // Alvo de toque de ~14pt sem alterar o layout: infla o frame, define a
            // área sensível e recolhe de volta com padding negativo.
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .padding(.vertical, -5)
            .gesture(seekGesture(width: geo.size.width, duration: duration), isEnabled: isSeekable)
        }
        .frame(height: 4)
        .animation(.linear(duration: 0.5), value: playbackFraction)
        // Área interativa precisa se excluir do arrasto da janela — caso contrário
        // arrastar para buscar move o widget (`DECISOES.md · 2026-08-05 · #01`).
        .modifier(NonDraggableIf(isSeekable))
        .help(isSeekable ? L10n.dragToSeek : "")
    }

    private func seekGesture(width: CGFloat, duration: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragFraction = min(max(value.location.x / max(width, 1), 0), 1)
            }
            .onEnded { value in
                let fraction = min(max(value.location.x / max(width, 1), 0), 1)
                nowPlaying.seek(to: fraction * duration)
                dragFraction = nil
            }
    }

    /// O espaçamento de 14 compensa o alvo de clique de 28pt de cada botão: os
    /// centros ficam a ~42pt um do outro, como no espaçamento de 26 sobre os
    /// glifos nus de antes.
    private var controls: some View {
        // Prev/next só existem sobre uma sessão viva; o play não, porque é ele que
        // abre o player e cria a sessão. Desabilitar em vez de mandar às cegas evita
        // que o comando global caia no app errado.
        let canTransport = nowPlaying.canControlTransport
        let reason = nowPlaying.transportUnavailableReason ?? ""

        return HStack(spacing: 14) {
            button("backward.fill", size: 15) { nowPlaying.previous() }
                .disabled(!canTransport)
                .help(reason)
            button(track.isPlaying ? "pause.fill" : "play.fill", size: 18) {
                nowPlaying.playPause()
            }
            button("forward.fill", size: 15) { nowPlaying.next() }
                .disabled(!canTransport)
                .help(reason)
        }
        .foregroundStyle(.primary)
        .nonDraggableWindowArea()
    }

    /// Sidebar de volume fixa, na lateral direita do card: slider vertical com o
    /// botão de mute abaixo.
    ///
    /// O alvo depende da fonte — volume do próprio app onde existe AppleScript, volume
    /// de saída do sistema no resto (ver `VolumeRouter`). Como o mesmo controle muda de
    /// significado, o alvo é dito no tooltip; sem isso o usuário não teria como saber
    /// por que às vezes o volume do Mac inteiro se mexe e às vezes não.
    private var volumeSidebar: some View {
        VStack(spacing: 8) {
            VolumeSlider(value: volume.volume, vertical: true) { volume.setVolume($0) }
                .frame(width: 20, height: 104)

            muteButton
        }
        .foregroundStyle(.secondary)
        .frame(width: 24)
        .help(volume.target.label)
        .nonDraggableWindowArea()
    }

    /// Versão horizontal do controle de volume, para o formato 1×1: botão de mute à
    /// esquerda e slider ocupando o resto da linha. Mesmo alvo e mesmo tooltip da
    /// sidebar — só muda a orientação.
    private var volumeFooter: some View {
        HStack(spacing: 6) {
            muteButton
            VolumeSlider(value: volume.volume, vertical: false) { volume.setVolume($0) }
                .frame(height: 16)
        }
        .foregroundStyle(.secondary)
        .help(volume.target.label)
        .nonDraggableWindowArea()
    }

    private var muteButton: some View {
        Button { volume.toggleMute() } label: {
            Image(systemName: speakerSymbol)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 24, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var speakerSymbol: String {
        if volume.isMuted || volume.volume == 0 { return "speaker.slash.fill" }
        switch volume.volume {
        case ..<0.33: return "speaker.wave.1.fill"
        case ..<0.66: return "speaker.wave.2.fill"
        default: return "speaker.wave.3.fill"
        }
    }

    /// O `contentShape` vem depois do `frame` de propósito: é ele que faz o
    /// clique valer nos 28×28 inteiros, e não apenas sobre o glifo.
    private func button(_ systemName: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .medium))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
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

/// `NSSlider` nativo, vertical ou horizontal. Usado em vez de um `Slider` SwiftUI
/// rotacionado: a rotação desloca a área de hit-test, fazendo o clique cair no
/// "fundo" da janela (que é movível) em vez de no controle. O `NSSlider` mantém o
/// hit-testing correto e marca sua área como não-movível.
struct VolumeSlider: NSViewRepresentable {
    var value: Double
    var vertical: Bool
    var onChange: (Double) -> Void

    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider(
            value: value, minValue: 0, maxValue: 1,
            target: context.coordinator,
            action: #selector(Coordinator.changed(_:))
        )
        slider.isVertical = vertical
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
