import Combine
import SwiftUI

/// Linha de status do menu (bandeja e contexto do widget): ícone play/pause + faixa
/// atual. Vive numa view custom de `NSMenuItem` com largura fixa — nome de música
/// longo roda em letreiro (`MarqueeText`) em vez de esticar o menu inteiro. Observa o
/// `NowPlayingController`, então o estado atualiza ao vivo enquanto o menu está aberto.
struct MenuStatusView: View {
    @ObservedObject var nowPlaying: NowPlayingController
    /// Largura total da linha. Explícita porque o `NSHostingView` dentro de menu faz
    /// o layout pelo tamanho ideal do conteúdo — propostas flexíveis
    /// (`maxWidth: .infinity`) não são limitadas pela largura do item, e o letreiro
    /// nunca enxergaria overflow.
    let width: CGFloat

    private var marqueeWidth: CGFloat {
        // leading 14 + ícone 14 + spacing 6 + trailing 12
        width - 46
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: nowPlaying.track.isPlaying ? "play.fill" : "pause.fill")
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 14)
            MarqueeText(text: statusText, availableWidth: marqueeWidth)
                .id(statusText)
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .frame(width: width, height: 24)
    }

    private var statusText: String {
        let track = nowPlaying.track
        if let name = track.title, track.hasContent {
            return track.isPlaying ? L10n.playingTrack(name) : L10n.pausedTrack(name)
        }
        return L10n.nothingPlaying
    }
}

/// Texto de uma linha que rola em loop (letreiro) quando não cabe no espaço
/// disponível; quando cabe, fica parado. O loop é texto duplicado com um respiro
/// (`gap`) entre as cópias, com uma pausa no ponto inicial a cada volta.
///
/// A rolagem é dirigida por um `Timer` em modo `.common`, não por animação SwiftUI:
/// o menu segura o run loop em modo de tracking e as animações do Core Animation
/// **não rodam** ali — só timer em `.common` dispara (mesmo truque do auto-fechamento
/// no `AppMenuController`).
///
/// Troca de texto é tratada pelo call site com `.id(texto)`: a view renasce com
/// estado zerado e mede/anima do zero.
struct MarqueeText: View {
    let text: String
    /// Espaço horizontal em que o texto precisa caber. Explícito — ver nota na
    /// `MenuStatusView` sobre propostas flexíveis dentro de menu.
    let availableWidth: CGFloat
    /// Velocidade de rolagem, em pontos por segundo.
    var speed: CGFloat = 30
    /// Respiro entre o fim do texto e a cópia seguinte.
    var gap: CGFloat = 32
    /// Pausa no ponto inicial a cada volta do letreiro.
    var holdDuration: TimeInterval = 1.2

    private static let tickInterval: TimeInterval = 1.0 / 30.0

    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var holdRemaining: TimeInterval = 1.2

    private let clock = Timer.publish(
        every: Self.tickInterval, on: .main, in: .common
    ).autoconnect()

    private var overflows: Bool {
        textWidth > availableWidth
    }

    var body: some View {
        HStack(spacing: gap) {
            Text(text)
                .lineLimit(1)
                .fixedSize()
                .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) {
                    textWidth = $0
                }
            if overflows {
                Text(text)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .offset(x: offset)
        .frame(width: availableWidth, alignment: .leading)
        .clipped()
        .mask(edgeFade)
        .onReceive(clock) { _ in
            tick()
        }
    }

    private func tick() {
        guard overflows else { return }
        if holdRemaining > 0 {
            holdRemaining -= Self.tickInterval
            return
        }
        offset -= speed * Self.tickInterval
        // Uma volta completa: a cópia está exatamente onde o original começou.
        if offset <= -(textWidth + gap) {
            offset = 0
            holdRemaining = holdDuration
        }
    }

    /// Esvaece as bordas durante a rolagem, como o Now Playing do sistema. Sem
    /// overflow, máscara cheia — texto parado não precisa de fade.
    @ViewBuilder
    private var edgeFade: some View {
        if overflows {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.03),
                    .init(color: .black, location: 0.92),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            Color.black
        }
    }

}
