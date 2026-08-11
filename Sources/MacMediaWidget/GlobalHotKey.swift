import AppKit
import Carbon.HIToolbox

/// Atalho de teclado global registrado via Carbon (`RegisterEventHotKey`).
///
/// É o único caminho que funciona com o app em background sem pedir permissão de
/// Acessibilidade e sem dependência externa: `NSEvent.addGlobalMonitor` exige
/// Acessibilidade, e o `KeyboardShortcuts`/`HotKey` do ecossistema seriam uma
/// dependência a mais para embrulhar exatamente esta mesma API.
@MainActor
final class GlobalHotKey {
    // `nonisolated(unsafe)` só para o deinit (nonisolated) poder liberar os handles.
    // Não há corrida real: ambos são escritos uma vez no init e lidos no deinit, e o
    // dono mantém a instância no MainActor pelo ciclo de vida inteiro do app.
    nonisolated(unsafe) private var hotKeyRef: EventHotKeyRef?
    nonisolated(unsafe) private var handlerRef: EventHandlerRef?
    private let action: () -> Void

    /// Registra o atalho. Padrão: ⌃⌥⌘M (M de mídia) — três modificadores para não
    /// colidir com atalho de outro app.
    init(
        keyCode: Int = kVK_ANSI_M,
        modifiers: Int = controlKey | optionKey | cmdKey,
        action: @escaping () -> Void
    ) {
        self.action = action

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        // O handler é um ponteiro de função C: não captura contexto, então `self`
        // viaja pelo userData. `passUnretained` porque o dono (AppDelegate) mantém a
        // instância viva pelo ciclo de vida inteiro do app.
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                // Eventos Carbon são entregues no dispatcher da main thread.
                MainActor.assumeIsolated { hotKey.action() }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )

        let hotKeyID = EventHotKeyID(signature: OSType(0x4D4D_5747), id: 1) // 'MMWG'
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        if status != noErr {
            NSLog("MacMediaWidget: falha ao registrar o atalho global (status \(status))")
        }
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
