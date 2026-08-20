import AppKit

/// `Spotify.app` — o segundo player da lista com dicionário AppleScript, e por isso o
/// segundo que o widget consegue **endereçar** sem ser dono da sessão de Now Playing.
///
/// Tudo o que está declarado aqui foi medido contra o app real
/// (`docs/compatibilidade-players.md`): posição real, seek pelos dois caminhos
/// (AppleScript e MediaRemote), volume por-app, `shuffling`/`repeating` e comando
/// endereçado — este último provado com o Apple Music tocando ao mesmo tempo.
@MainActor
final class SpotifyPlayer: AppleScriptPlayer {
    nonisolated static let bundleID = "com.spotify.client"

    nonisolated static let installURL: URL? = URL(string: "https://www.spotify.com/download/mac/")

    init() {
        super.init(
            bundleIdentifier: Self.bundleID,
            displayName: "Spotify",
            scriptingName: "Spotify"
        )
    }

    /// Uma armadilha em `.appVolume`, medida em 8 pontos: o `sound volume` do Spotify
    /// **quantiza em `n-1`** em todo valor intermediário (pedido 42 lê 41; 63 lê 62), só
    /// acertando em 0 e 100. Quem gravar e reler para confirmar vai concluir que falhou,
    /// e um slider preso ao valor lido recua um ponto a cada ajuste
    /// (`docs/compatibilidade-players.md`, nota ²).
    override var scriptedCapabilities: PlayerCapabilities {
        [.realPosition, .seek, .appVolume, .shuffleRepeat, .directedControl]
    }

    /// O que sobrevive à Automação negada. O `elapsedTime` do Spotify no stream não é um
    /// relógio: é uma âncora reemitida a cada faixa e a cada seek — que é exatamente o
    /// que o controller faz com ela. E o seek continua indo pelo MediaRemote, que o app
    /// obedece (faixa de 178,5 s posicionada em 172,52 s trocou 5 s depois).
    override var unscriptedCapabilities: PlayerCapabilities {
        [.fullTransport, .streamPosition, .seek, .reliablePlaybackState]
    }

    override var installURL: URL? { Self.installURL }
}
