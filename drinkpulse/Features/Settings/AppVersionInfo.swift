import Foundation

struct AppVersionInfo: Equatable, Sendable {
    let version: String?
    let build: String?

    init(infoDictionary: [String: Any]?) {
        version = Self.string(for: "CFBundleShortVersionString", in: infoDictionary)
        build = Self.string(for: "CFBundleVersion", in: infoDictionary)
    }

    /// Evaluated once per launch (Bundle.main.infoDictionary does not change at runtime).
    static let current = AppVersionInfo(infoDictionary: Bundle.main.infoDictionary)

    var displayText: String {
        switch (version, build) {
        case let (version?, build?):
            return String(
                format: String(localized: String.LocalizationValue("settings.version.full")),
                version, build
            )
        case let (version?, nil):
            return String(
                format: String(localized: String.LocalizationValue("settings.version.only")),
                version
            )
        case (nil, _):
            return String(localized: "settings.version.unknown")
        }
    }

    private static func string(for key: String, in dictionary: [String: Any]?) -> String? {
        guard let value = dictionary?[key] as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
