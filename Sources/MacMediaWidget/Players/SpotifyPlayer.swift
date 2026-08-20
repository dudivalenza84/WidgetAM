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

    override var scriptedCapabilities: PlayerCapabilities {
        [.realPosition, .seek, .appVolume, .shuffleRepeat, .directedControl]
    }

    /// O `elapsedTime` do Spotify no stream não é um relógio: é uma âncora reemitida a
    /// cada faixa e a cada seek. Serve exatamente para o que o controller faz com ela —
    /// fixar o ponto de partida e continuar estimando por tempo de parede.
    override var unscriptedCapabilities: PlayerCapabilities { [.fullTransport, .streamPosition] }

    override var installURL: URL? { Self.installURL }

    // MARK: - Transporte (endereçado, funciona fora da sessão ativa)

    override func playPause() { fireIfRunning("playpause") }

    /// O único comando que pode abrir o app: é o play do widget assumindo o player.
    override func play() { fire("play") }

    override func next() { fireIfRunning("next track") }
    override func previous() { fireIfRunning("previous track") }

    // MARK: - Posição

    override func position() async -> Double? {
        guard isRunning else { return nil }
        return AppleScriptRunner.number(from: await tell("get player position"))
    }

    override func seek(to seconds: Double) {
        fireIfRunning("set player position to \(Int(seconds.rounded()))")
    }

    // MARK: - Volume por-app (0–100 no dicionário, 0…1 no protocolo)

    /// Atenção ao ler de volta: o `sound volume` do Spotify **quantiza em `n-1`** em
    /// todo valor intermediário (pedido 42 lê 41; 63 lê 62), só acertando em 0 e 100.
    /// Quem gravar e reler para confirmar vai concluir que falhou, e um slider preso ao
    /// valor lido recua um ponto a cada ajuste. Medido em 8 pontos
    /// (`docs/compatibilidade-players.md`, nota ²).
    override func volume() async -> Double? {
        guard isRunning else { return nil }
        guard let level = AppleScriptRunner.number(from: await tell("get sound volume")) else {
            return nil
        }
        return level / 100
    }

    override func setVolume(_ value: Double) {
        let level = Int((min(max(value, 0), 1) * 100).rounded())
        fireIfRunning("set sound volume to \(level)")
    }
}
