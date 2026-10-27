import Foundation

/// Links configured in Config/Signing.xcconfig (via Info.plist).
enum AppLinks {
    /// The privacy policy page (`IROVI_PRIVACY_URL`), or nil if not set.
    static var privacyPolicy: URL? {
        guard let text = Bundle.main.object(forInfoDictionaryKey: "IroviPrivacyPolicyURL") as? String,
              text.hasPrefix("https://") else { return nil }
        return URL(string: text)
    }
}
