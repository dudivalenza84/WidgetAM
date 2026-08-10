import AppKit

/// Resolve um `bundleIdentifier` no `Player` que sabe controlá-lo.
///
/// Players "conhecidos" são os que ganharam uma implementação específica — hoje só os
/// que têm AppleScript rende algo além do transporte. Qualquer outra fonte cai no
/// `MediaRemotePlayer` genérico, que funciona sem saber o que é: é assim que uma aba de
/// navegador ou um player que ninguém previu continuam controláveis.
@MainActor
final class PlayerRegistry {
    static let shared = PlayerRegistry()

    /// Fábricas dos players com implementação própria, por bundle id.
    private let builders: [String: () -> Player] = [
        AmazonMusicPlayer.bundleID: { AmazonMusicPlayer() },
        AppleMusicPlayer.bundleID: { AppleMusicPlayer() },
    ]

    /// Instâncias já criadas. Players guardam estado (capacidade rebaixada por
    /// automação negada, por exemplo), então não podem ser recriados a cada consulta.
    private var cache: [String: Player] = [:]

    /// O player que controla a fonte informada. `nil` só quando não há fonte alguma.
    func player(for bundleIdentifier: String?) -> Player? {
        guard let id = bundleIdentifier, !id.isEmpty else { return nil }
        if let existing = cache[id] { return existing }
        let player = builders[id]?() ?? MediaRemotePlayer(bundleIdentifier: id)
        cache[id] = player
        return player
    }

    /// Players com implementação própria que estão instalados nesta máquina.
    /// Base do seletor de player preferido e da detecção de onboarding.
    func installedKnownPlayers() -> [Player] {
        builders.keys
            .compactMap { player(for: $0) }
            .filter(\.isInstalled)
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
