import SwiftUI

/// Linha de transporte do menu (bandeja e contexto do widget): três botões lado a
/// lado, no estilo do menu de Now Playing do Controle Central. Vive numa view custom
/// de `NSMenuItem` — por isso clicar **não fecha** o menu, e dá para pausar e pular
/// faixas em sequência sem reabrir.
struct MenuTransportView: View {
    @ObservedObject var nowPlaying: NowPlayingController

    var body: some View {
        HStack(spacing: 20) {
            TransportButton(
                symbol: "backward.fill",
                label: L10n.previousTrack
            ) { nowPlaying.previous() }
                .disabled(!nowPlaying.canSkipPrevious)

            TransportButton(
                symbol: nowPlaying.playPauseSymbol,
                label: L10n.playPause
            ) { nowPlaying.playPause() }

            TransportButton(
                symbol: "forward.fill",
                label: L10n.nextTrack
            ) { nowPlaying.next() }
                .disabled(!nowPlaying.canSkipNext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3)
    }
}

/// Botão de símbolo com realce de hover — `NSMenuItem` com view não ganha o highlight
/// nativo do menu, então o feedback visual é por nossa conta.
private struct TransportButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 32, height: 24)
                .contentShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.primary.opacity(isHovering ? 0.12 : 0))
        )
        .onHover { isHovering = $0 }
        .accessibilityLabel(label)
        .help(label)
    }
}
