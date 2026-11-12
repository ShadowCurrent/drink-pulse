import Foundation

struct AppVersionInfo: Equatable, Sendable {
    let version: String?
    let build: String?
    let buildDate: Date?
    let gitCommit: String?
    let isDebug: Bool

    init(
        infoDictionary: [String: Any]?,
        buildDate: Date? = nil,
        gitCommit: String? = nil,
        isDebug: Bool = false
    ) {
        version = Self.string(for: "CFBundleShortVersionString", in: infoDictionary)
        build = Self.string(for: "CFBundleVersion", in: infoDictionary)
        self.buildDate = buildDate
        self.gitCommit = Self.trimmedNonEmpty(gitCommit)
        self.isDebug = isDebug
    }

    /// Evaluated once per launch so the Debug-only file read does not repeat per view update.
    static let current = AppVersionInfo(
        infoDictionary: Bundle.main.infoDictionary,
        buildDate: readExecutableDate(),
        gitCommit: readGitCommit(),
        isDebug: isDebugBuild
    )

    var displayText: String {
        var text = versionLine
        guard isDebug else { return text }
        text += " · " + String(localized: "settings.version.debug")
        var details: [String] = []
        if let buildDate {
            details.append(String(
                format: String(localized: String.LocalizationValue("settings.version.built")),
                Self.formatBuildDate(buildDate)
            ))
        }
        if let gitCommit {
            details.append(gitCommit)
        }
        if !details.isEmpty {
            text += "\n" + details.joined(separator: " · ")
        }
        return text
    }

    /// Fixed, sortable, locale-independent stamp (developer-facing, intentionally not localized).
    static func formatBuildDate(_ date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private var versionLine: String {
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
        trimmedNonEmpty(dictionary?[key] as? String)
    }

    private static func trimmedNonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private static var isDebugBuild: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    /// The only place a file timestamp is read. Debug-only: that API category is a
    /// required-reason API (privacy manifest), and an executable's timestamp is not
    /// guaranteed to be the build date for App Store installs.
    private static func readExecutableDate() -> Date? {
        #if DEBUG
        guard let path = Bundle.main.executableURL?.path else { return nil }
        // try? is fine: a missing build time only drops the second line; no user data involved.
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return attributes?[.modificationDate] as? Date
        #else
        return nil
        #endif
    }

    /// Short commit SHA written into the bundle by the "Embed Git Commit (Debug)"
    /// Run Script phase. Release builds neither write nor read the file.
    private static func readGitCommit() -> String? {
        #if DEBUG
        guard let url = Bundle.main.url(forResource: "GitCommit", withExtension: "txt") else { return nil }
        // try? is fine: a missing SHA only drops it from the Debug footer.
        return try? String(contentsOf: url, encoding: .utf8)
        #else
        return nil
        #endif
    }
}
