import Foundation

/// Versão do app para exibição ao usuário (menu e Preferências).
///
/// A fonte é o `CFBundleShortVersionString` do Info.plist — a mesma que o Finder mostra.
/// Rodando o binário solto do SPM em desenvolvimento não há Info.plist, e o fallback
/// "dev" diz exatamente o que aquele build é.
enum AppVersion {
    static var current: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "dev"
    }
}
