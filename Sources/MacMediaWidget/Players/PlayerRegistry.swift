import AppKit

/// Resolve um `bundleIdentifier` no `Player` que sabe controlá-lo.
///
/// Players com implementação própria vêm do `PlayerCatalog` — hoje só os que têm
/// AppleScript rendem algo além do transporte. Qualquer outra fonte cai no
/// `MediaRemotePlayer` genérico, que funciona sem saber o que é: é assim que uma aba de
/// navegador ou um player que ninguém previu continuam controláveis.
///
/// O registry responde "quem controla **esta sessão**"; o catálogo responde "o que o
/// usuário pode escolher". São perguntas diferentes, e por isso os dois existem.
@MainActor
final class PlayerRegistry {
    static let shared = PlayerRegistry()

    /// Instâncias já criadas. Players guardam estado (capacidade rebaixada por
    /// automação negada, por exemplo), então não podem ser recriados a cada consulta.
    private var cache: [String: Player] = [:]

    /// O player que controla a fonte informada. `nil` só quando não há fonte alguma.
    func player(for bundleIdentifier: String?) -> Player? {
        guard let id = bundleIdentifier, !id.isEmpty else { return nil }
        if let existing = cache[id] { return existing }
        let player = PlayerCatalog.entry(for: id)?.make() ?? MediaRemotePlayer(bundleIdentifier: id)
        cache[id] = player
        return player
    }

    /// Players do catálogo que identificam sessão, instalados nesta máquina.
    /// Base do seletor de player preferido e da detecção de onboarding.
    func installedCatalogPlayers() -> [Player] {
        PlayerCatalog.appEntries
            .compactMap { player(for: $0.id) }
            .filter(\.isInstalled)
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
