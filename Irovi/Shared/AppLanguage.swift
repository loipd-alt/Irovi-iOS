import Foundation

/// The language the user picked inside Irovi (or "follow the iPhone").
/// Stored in the App Group so the widget follows the same choice.
/// Raw values are the .lproj names; adding a language = a case here, its
/// strings in scripts/strings/, its articles in Resources/Articles/, and its
/// code in CFBundleLocalizations.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case en, vi, es
    case ptBR = "pt-BR"
    case fr, de, ja
    case indonesian = "id"

    static let key = "appLanguage"
    static let store = UserDefaults(suiteName: WidgetSnapshot.appGroup) ?? .standard

    var id: String { rawValue }

    static var current: AppLanguage {
        AppLanguage(rawValue: store.string(forKey: key) ?? "") ?? .system
    }

    /// The localization actually shown, e.g. "en", "vi", "pt-BR".
    var code: String {
        guard self == .system else { return rawValue }
        let preferred = Bundle.main.preferredLocalizations.first ?? "en"
        return AppLanguage(rawValue: preferred).map(\.rawValue) ?? "en"
    }

    /// The .lproj folder for `code`, used to look strings up in that language
    /// without restarting the app.
    var bundle: Bundle {
        Bundle.main.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
    }

    /// Locale for SwiftUI text and for dates and numbers. "Follow the iPhone"
    /// keeps the phone's own locale (and its region formats).
    var locale: Locale {
        switch self {
        case .system: .autoupdatingCurrent
        case .en: Locale(identifier: "en_\(Locale.current.region?.identifier ?? "US")")
        case .vi: Locale(identifier: "vi_VN")
        default: Locale(identifier: rawValue)
        }
    }

    /// The language's own name, so people can find theirs whatever is showing.
    var nativeName: String {
        switch self {
        case .system: localized("Use iPhone language")
        case .en: "English"
        case .vi: "Tiếng Việt"
        case .es: "Español"
        case .ptBR: "Português (Brasil)"
        case .fr: "Français"
        case .de: "Deutsch"
        case .ja: "日本語"
        case .indonesian: "Bahasa Indonesia"
        }
    }

    var flag: String? {
        switch self {
        case .system: nil
        case .en: "🇬🇧"
        case .vi: "🇻🇳"
        case .es: "🇪🇸"
        case .ptBR: "🇧🇷"
        case .fr: "🇫🇷"
        case .de: "🇩🇪"
        case .ja: "🇯🇵"
        case .indonesian: "🇮🇩"
        }
    }
}

/// A string from the catalog in the language picked in Irovi. Use this instead
/// of `String(localized:)` for text built in code (food names, notifications…).
func localized(_ value: String.LocalizationValue) -> String {
    String(localized: value, bundle: AppLanguage.current.bundle)
}
