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
        window.title = "Preferências"
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
            Section("Player") {
                Picker("Player preferido", selection: $settings.preferredPlayerBundleId) {
                    ForEach(players, id: \.bundleIdentifier) { player in
                        Text(player.displayName).tag(player.bundleIdentifier)
                    }
                }

                Picker("Modo de controle", selection: $settings.controlMode) {
                    ForEach(ControlMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }

                Text(controlModeExplanation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Posicionamento") {
                Toggle("Alinhar à grade de widgets do macOS", isOn: $settings.snapToGrid)
                Text("A grade é a mesma dos widgets nativos da mesa: com algum widget nativo visível, o alinhamento é medido por ele; sem nenhum, usa a geometria padrão do sistema.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Aparência") {
                LabeledContent("Opacidade do tint") {
                    HStack {
                        Slider(value: $settings.tintOpacity, in: 0...1)
                        Text("\(Int(settings.tintOpacity * 100))%")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)
                    }
                }
            }

            Section("Comportamento") {
                Toggle(
                    "Abrir o \(preferredPlayerName) ao dar play (se estiver fechado)",
                    isOn: $settings.autoLaunchOnPlay
                )
                Toggle("Abrir no login", isOn: Binding(
                    get: { LoginItem.isEnabled },
                    set: { _ in LoginItem.toggle() }
                ))
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
        preferredPlayer?.displayName ?? "player preferido"
    }

    /// O texto muda com o modo **e** com o player, porque a limitação é real e
    /// depende dos dois: no modo fixo, um player sem AppleScript só obedece enquanto
    /// for quem está tocando. Esconder isso geraria a impressão de app quebrado.
    private var controlModeExplanation: String {
        switch settings.controlMode {
        case .automatic:
            return "O widget espelha o que estiver tocando, seja qual for o app. "
                + "O player preferido é o que ele abre quando você dá play sem nada tocando."
        case .fixed:
            let name = preferredPlayerName
            if preferredPlayer?.capabilities.contains(.directedControl) == true {
                return "O widget controla sempre o \(name), mesmo com outro app tocando."
            }
            return "O widget controla sempre o \(name) — mas ele não tem AppleScript, "
                + "então só responde enquanto for o app que está tocando. Com outro app "
                + "no comando, o play abre o \(name) e os demais controles ficam inativos."
        }
    }
}
