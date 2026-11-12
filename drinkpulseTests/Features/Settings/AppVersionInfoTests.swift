import Testing
import Foundation
@testable import drinkpulse

@MainActor
struct AppVersionInfoTests {

    private let dict: [String: Any] = [
        "CFBundleShortVersionString": "1.0",
        "CFBundleVersion": "1",
    ]

    private var utc: TimeZone { TimeZone(identifier: "UTC")! }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = utc
        return cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    // MARK: - Release

    @Test func displayText_returnsVersionAndBuild_whenReleaseBuild() {
        let info = AppVersionInfo(infoDictionary: dict)
        #expect(info.displayText == "Version 1.0 (1)")
    }

    @Test func displayText_ignoresBuildDate_whenReleaseBuild() {
        let info = AppVersionInfo(infoDictionary: dict, buildDate: date(2026, 11, 12, 14, 32), isDebug: false)
        #expect(info.displayText == "Version 1.0 (1)")
    }

    // MARK: - Debug

    @Test func displayText_appendsDebugMarker_whenDebugWithoutDate() {
        let info = AppVersionInfo(infoDictionary: dict, buildDate: nil, isDebug: true)
        #expect(info.displayText == "Version 1.0 (1) · Debug")
    }

    @Test func displayText_addsBuiltLine_whenDebugWithDate() {
        let when = date(2026, 11, 12, 14, 32)
        let info = AppVersionInfo(infoDictionary: dict, buildDate: when, isDebug: true)
        let expected = "Version 1.0 (1) · Debug\nBuilt " + AppVersionInfo.formatBuildDate(when)
        #expect(info.displayText == expected)
    }

    @Test func displayText_appendsDebugMarker_whenVersionMissingInDebug() {
        let info = AppVersionInfo(infoDictionary: nil, buildDate: nil, isDebug: true)
        #expect(info.displayText == "Version unavailable · Debug")
    }

    // MARK: - Git commit

    @Test func displayText_appendsCommitToBuiltLine_whenDebugWithDateAndCommit() {
        let when = date(2026, 11, 12, 14, 32)
        let info = AppVersionInfo(infoDictionary: dict, buildDate: when, gitCommit: "abc1234", isDebug: true)
        let expected = "Version 1.0 (1) · Debug\nBuilt " + AppVersionInfo.formatBuildDate(when) + " · abc1234"
        #expect(info.displayText == expected)
    }

    @Test func displayText_showsCommitAlone_whenDebugWithoutDate() {
        let info = AppVersionInfo(infoDictionary: dict, gitCommit: "abc1234-dirty", isDebug: true)
        #expect(info.displayText == "Version 1.0 (1) · Debug\nabc1234-dirty")
    }

    @Test func displayText_ignoresCommit_whenReleaseBuild() {
        let info = AppVersionInfo(infoDictionary: dict, gitCommit: "abc1234", isDebug: false)
        #expect(info.displayText == "Version 1.0 (1)")
    }

    @Test func gitCommit_isNil_whenBlankOrWhitespace() {
        #expect(AppVersionInfo(infoDictionary: dict, gitCommit: " \n", isDebug: true).gitCommit == nil)
        #expect(AppVersionInfo(infoDictionary: dict, gitCommit: "abc1234\n").gitCommit == "abc1234")
    }

    // MARK: - formatBuildDate

    @Test func formatBuildDate_formatsUTC() {
        #expect(AppVersionInfo.formatBuildDate(date(2026, 11, 12, 14, 32), timeZone: utc) == "2026-11-12 14:32")
    }

    @Test func formatBuildDate_appliesInjectedTimeZone() {
        let warsaw = TimeZone(identifier: "Europe/Warsaw")!
        #expect(AppVersionInfo.formatBuildDate(date(2026, 11, 12, 14, 32), timeZone: warsaw) == "2026-11-12 15:32")
    }

    @Test func formatBuildDate_zeroPadsHourAndMinute() {
        #expect(AppVersionInfo.formatBuildDate(date(2026, 3, 4, 0, 5), timeZone: utc) == "2026-03-04 00:05")
    }

    // MARK: - Missing / malformed keys

    @Test func displayText_returnsVersionOnly_whenBuildMissingOrInvalid() {
        let variants: [[String: Any]] = [
            ["CFBundleShortVersionString": "1.0"],
            ["CFBundleShortVersionString": "1.0", "CFBundleVersion": ""],
            ["CFBundleShortVersionString": "1.0", "CFBundleVersion": "   "],
            ["CFBundleShortVersionString": "1.0", "CFBundleVersion": 7],
        ]
        for variant in variants {
            #expect(AppVersionInfo(infoDictionary: variant).displayText == "Version 1.0")
        }
    }

    @Test func displayText_returnsUnavailable_whenVersionMissingOrInvalid() {
        let variants: [[String: Any]?] = [
            nil,
            [:],
            ["CFBundleVersion": "1"],
            ["CFBundleShortVersionString": 1.0, "CFBundleVersion": "1"],
            ["CFBundleShortVersionString": "", "CFBundleVersion": "1"],
        ]
        for variant in variants {
            #expect(AppVersionInfo(infoDictionary: variant).displayText == "Version unavailable")
        }
    }

    // MARK: - current

    @Test func current_readsExpandedBundleValues() {
        let info = AppVersionInfo.current
        #expect(info.version?.isEmpty == false)
        #expect(info.version?.contains("$(") == false)
        #expect(info.build?.isEmpty == false)
        #expect(info.build?.contains("$(") == false)
        #if DEBUG
        #expect(info.isDebug)
        #expect(info.buildDate != nil)
        #endif
    }
}
