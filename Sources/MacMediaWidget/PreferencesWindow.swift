import AppKit
import SwiftUI

/// Janela de preferências do widget. Acessada pelo item "Preferências…" da
/// bandeja. Criada sob demanda e reaproveitada; ao reabrir, traz à frente.
@MainActor
final class PreferencesController: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingController(rootView: PreferencesView())
        let window = NSWindow(contentViewController: hosting)
        window.title = L10n.preferencesTitle
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

/// Formulário de preferências (SwiftUI). Liga diretamente ao `AppSettings`
/// compartilhado — as mudanças aplicam ao vivo no widget.
struct PreferencesView: View {
    @ObservedObject private var settings = AppSettings.shared

    /// Players que o usuário pode eleger como preferido: visíveis e instalados.
    /// Calculada, e não mais fixada na abertura da janela: os checkboxes da seção
    /// "Apps controlados" alteram esta lista na mesma tela, ao vivo.
    private var players: [Player] { PlayerRegistry.shared.selectablePlayers() }

    /// Catálogo inteiro, inclusive o que não está instalado — a lista é também a
    /// vitrine do que o widget suporta.
    private var catalogEntries: [PlayerCatalogEntry] {
        PlayerCatalog.entries.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            brandHeader
            form
        }
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Cabeçalho de marca: o ícone real do bundle (icns; genérico no binário solto de
    /// desenvolvimento), nome e versão — que por isso saiu do rodapé do formulário.
    private var brandHeader: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text("MacMediaWidget")
                    .font(.title3.weight(.semibold))
                Text("\(L10n.version) \(AppVersion.current)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }

    private var form: some View {
        Form {
            Section(L10n.sectionPlayer) {
                // A chave é `catalogID`, não `bundleIdentifier`: um atalho de serviço
                // web é escolhido pelo id do catálogo, e gravar o bundle do PWA aqui
                // deixaria a preferência apontando para fora do catálogo.
                Picker(L10n.preferredPlayer, selection: $settings.preferredPlayerBundleId) {
                    ForEach(players, id: \.catalogID) { player in
                        Text(player.displayName).tag(player.catalogID)
                    }
                }

                Picker(L10n.controlMode, selection: $settings.controlMode) {
                    ForEach(ControlMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }

                Text(controlModeExplanation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section(L10n.sectionControlledApps) {
                ForEach(catalogEntries, id: \.id) { entry in
                    appToggle(id: entry.id, name: entry.displayName, note: note(for: entry))
                }

                // Fontes que apareceram no Now Playing e não estão no catálogo: é o
                // único caminho para o usuário ocultar um player que ninguém previu.
                ForEach(settings.discoveredPlayerIDs, id: \.self) { id in
                    appToggle(
                        id: id,
                        name: MediaRemotePlayer.localizedName(forBundleIdentifier: id) ?? id,
                        note: nil
                    )
                }

                if !settings.discoveredPlayerIDs.isEmpty {
                    Button(L10n.forgetDiscovered) { settings.forgetDiscovered() }
                }

                Text(L10n.controlledAppsHelp)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section(L10n.sectionPlacement) {
                Toggle(L10n.keepAbove, isOn: $settings.keepAbove)
                Toggle(L10n.snapToGrid, isOn: $settings.snapToGrid)
                Text(L10n.snapToGridHelp)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section(L10n.sectionAppearance) {
                Picker(L10n.widgetSize, selection: $settings.widgetSize) {
                    ForEach(WidgetSize.allCases) { size in
                        Text(size.label).tag(size)
                    }
                }
                Text(L10n.widgetSizeHelp)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                LabeledContent(L10n.tintOpacity) {
                    HStack {
                        Slider(value: $settings.tintOpacity, in: 0...1)
                        Text("\(Int(settings.tintOpacity * 100))%")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)
                    }
                }
            }

            Section(L10n.sectionBehavior) {
                Toggle(
                    L10n.autoLaunchOnPlay(preferredPlayerName),
                    isOn: $settings.autoLaunchOnPlay
                )
                Toggle(L10n.openAtLogin, isOn: Binding(
                    get: { LoginItem.isEnabled },
                    set: { _ in LoginItem.toggle() }
                ))
                LabeledContent(L10n.bringToFrontShortcut) {
                    Text("⌃⌥⌘M").monospaced()
                }
                Text(L10n.bringToFrontShortcutHelp)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    /// Checkbox de um app controlado. Marcado = visível; a chave é a lista de ocultos.
    private func appToggle(id: String, name: String, note: String?) -> some View {
        Toggle(isOn: Binding(
            get: { !settings.isHidden(id) },
            set: { settings.setHidden(!$0, for: id) }
        )) {
            HStack(spacing: 8) {
                if let icon = PlayerRegistry.shared.player(for: id)?.icon {
                    Image(nsImage: icon).resizable().frame(width: 16, height: 16)
                }
                Text(name)
                if let note {
                    Text("· \(note)").foregroundStyle(.secondary)
                }
            }
        }
        // Desabilita só o que não dá para desmarcar; um app já oculto sempre pode voltar.
        .disabled(!settings.canHide(id) && !settings.isHidden(id))
    }

    /// Nota curta ao lado do nome: por que o app está esmaecido, ou o que ele é.
    private func note(for entry: PlayerCatalogEntry) -> String? {
        if entry.id == settings.preferredPlayerBundleId { return L10n.preferredCannotBeHidden }
        if case .shortcut = entry.kind { return L10n.opensInBrowser }
        if PlayerRegistry.shared.player(for: entry.id)?.isInstalled == false { return L10n.notInstalled }
        return nil
    }

    private var preferredPlayer: Player? {
        players.first { $0.catalogID == settings.preferredPlayerBundleId }
    }

    private var preferredPlayerName: String {
        preferredPlayer?.displayName ?? L10n.fallbackPlayerName
    }

    /// O texto muda com o modo **e** com o player, porque a limitação é real e
    /// depende dos dois: no modo fixo, um player sem AppleScript só obedece enquanto
    /// for quem está tocando. Esconder isso geraria a impressão de app quebrado.
    private var controlModeExplanation: String {
        switch settings.controlMode {
        case .automatic:
            return L10n.controlModeAutomaticHelp
        case .fixed:
            let name = preferredPlayerName
            if preferredPlayer?.capabilities.contains(.directedControl) == true {
                return L10n.controlModeFixedHelp(name)
            }
            return L10n.controlModeFixedHelpLimited(name)
        }
    }
}
