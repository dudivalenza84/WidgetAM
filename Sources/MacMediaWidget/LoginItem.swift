import Foundation
import ServiceManagement

/// Controla o autostart no login via SMAppService. Só funciona quando o app roda
/// a partir do bundle `.app` (não pelo binário solto do SPM em desenvolvimento).
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Liga/desliga a abertura automática no login. Retorna o estado resultante.
    @discardableResult
    static func toggle() -> Bool {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("MacMediaWidget: falha ao alternar autostart: \(error)")
        }
        return isEnabled
    }
}
