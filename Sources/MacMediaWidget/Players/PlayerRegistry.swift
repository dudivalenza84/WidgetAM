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

    /// Entradas do catálogo que o usuário pode escolher agora: visíveis, instaladas,
    /// incluindo os atalhos (que não identificam sessão mas são lançáveis).
    ///
    /// O filtro de instalação vale só para `kind == .app`. Um atalho tem a URL como
    /// destino garantido — o PWA do YouTube Music pode não estar instalado e ainda
    /// assim ser escolhível, e derrubá-lo por `isInstalled` o tiraria da lista sem motivo.
    func selectablePlayers() -> [Player] {
        PlayerCatalog.entries
            .filter { !AppSettings.shared.isHidden($0.id) }
            .compactMap { entrada -> Player? in
                guard let player = player(for: entrada.id) else { return nil }
                if case .app = entrada.kind, !player.isInstalled { return nil }
                return player
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
