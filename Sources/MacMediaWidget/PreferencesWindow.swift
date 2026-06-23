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

    var body: some View {
        Form {
            Section("Posicionamento") {
                LabeledContent("Margem da borda") {
                    HStack {
                        Slider(value: $settings.edgeMargin, in: 0...80)
                        Text("\(Int(settings.edgeMargin)) pt")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)
                    }
                }
                LabeledContent("Passo da grade vertical") {
                    HStack {
                        Stepper(value: $settings.gridStepY, in: 1...32, step: 1) {
                            EmptyView()
                        }
                        Text("\(Int(settings.gridStepY)) pt")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)
                    }
                }
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
                    "Abrir o Amazon Music ao dar play (se estiver fechado)",
                    isOn: $settings.autoLaunchOnPlay
                )
                Toggle("Abrir no login", isOn: Binding(
                    get: { LoginItem.isEnabled },
                    set: { _ in LoginItem.toggle() }
                ))
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }
}
