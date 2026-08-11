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

    /// Players com implementação própria instalados nesta máquina. Fixado uma vez por
    /// abertura da janela: instalar um player com as preferências abertas é raro o
    /// bastante para não valer um observador do LaunchServices.
    private let players = PlayerRegistry.shared.installedKnownPlayers()

    var body: some View {
        Form {
            Section(L10n.sectionPlayer) {
                Picker(L10n.preferredPlayer, selection: $settings.preferredPlayerBundleId) {
                    ForEach(players, id: \.bundleIdentifier) { player in
                        Text(player.displayName).tag(player.bundleIdentifier)
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

            Section(L10n.sectionPlacement) {
                Toggle(L10n.keepAbove, isOn: $settings.keepAbove)
                Toggle(L10n.snapToGrid, isOn: $settings.snapToGrid)
                Text(L10n.snapToGridHelp)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section(L10n.sectionAppearance) {
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

            Section {
                LabeledContent(L10n.version) {
                    Text(AppVersion.current)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var preferredPlayer: Player? {
        players.first { $0.bundleIdentifier == settings.preferredPlayerBundleId }
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
