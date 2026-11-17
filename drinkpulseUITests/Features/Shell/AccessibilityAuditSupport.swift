import XCTest

/// Builds the stable, language-independent key an audit issue is recorded under.
///
/// The simulator system language may be Polish, so keys never use the localized issue
/// description. They hold the audit type name and an element key only.
@MainActor
enum AccessibilityAuditKey {

    /// Lower-camel name of an audit type; any other type maps to `raw` plus the raw value.
    /// `action` and `parentChild` exist only on macOS (XCUIAccessibilityAuditTypes.h), so on iOS
    /// they fall through to the raw form.
    static func typeName(for type: XCUIAccessibilityAuditType) -> String {
        switch type {
        case .contrast: "contrast"
        case .elementDetection: "elementDetection"
        case .hitRegion: "hitRegion"
        case .sufficientElementDescription: "sufficientElementDescription"
        case .dynamicType: "dynamicType"
        case .textClipped: "textClipped"
        case .trait: "trait"
        default: "raw\(type.rawValue)"
        }
    }

    /// Identifier, else label. An element with neither (or no element) gets a locatable key:
    /// `none#type=<elementType rawValue>@x,y,w,h` with the frame rounded to integers.
    static func elementKey(for element: XCUIElement?) -> String {
        guard let element else { return "none#type=nil" }
        let named = [element.identifier, element.label].first { !$0.isEmpty }
        let raw = named ?? unlabeledKey(for: element)
        return raw
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: " ")
    }

    private static func unlabeledKey(for element: XCUIElement) -> String {
        let frame = element.frame
        let rect = [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height]
            .map { String(Int($0.rounded())) }
            .joined(separator: ",")
        return "none#type=\(element.elementType.rawValue)@\(rect)"
    }
}

/// Launch arguments shared by every audit variant.
enum AuditLaunch {

    static let ax5Category = "UICTContentSizeCategoryAccessibilityXXXL"

    /// Seeded multi-day arguments, or the onboarding arguments, plus an optional content size.
    ///
    /// Every variant also forces the in-app Appearance setting to "system". The setting is stored
    /// in the app's user defaults and survives between launches (SettingsUITests switches it to
    /// Light or Dark), and a stored Light or Dark overrides the simulator appearance that
    /// `pinAppearance` sets. A launch argument takes precedence over the stored value, so the
    /// app follows the pinned appearance whatever an earlier test or session stored.
    static func arguments(onboarding: Bool, contentSizeCategory: String?) -> [String] {
        var arguments: [String]
        if onboarding {
            arguments = [
                "-dp_uitest", "YES",
                "-dp_force_onboarding", "YES",
            ]
        } else {
            arguments = [
                "-dp_onboarding_done", "YES",
                "-dp_uitest", "YES",
                "-dp_uitest_dataset", "multiday",
                "-dp_uitest_unit", "metric",
            ]
        }
        arguments += ["-dp_color_scheme", "system"]
        if let contentSizeCategory {
            arguments += ["-UIPreferredContentSizeCategoryName", contentSizeCategory]
        }
        return arguments
    }
}

/// Shared helpers for the per-screen audit tests of Phase 11.
///
/// The all-screens helpers take the audit types from the caller and report every issue as one
/// `XCTFail`. They hold no global allow-list and exclude no type. The only way to let a finding
/// pass is the explicit, per-call `exemptElementKeys` parameter, which exists for the narrow owner
/// decision D11-28 (system-owned Form controls at AX5) and applies to `dynamicType` and
/// `textClipped` findings only; a contrast, hit-region or description finding is never exempt.
extension XCTestCase {

    /// Pins the simulator-global appearance and restores the value read before the change when the
    /// test ends, so a failure cannot leave the simulator dark. The simulator rejects `.unspecified`,
    /// so a restore of that value becomes `.light`.
    @MainActor
    func pinAppearance(_ appearance: XCUIDevice.Appearance) {
        let previous = XCUIDevice.shared.appearance
        let restored: XCUIDevice.Appearance = previous == .unspecified ? .light : previous
        addTeardownBlock {
            await MainActor.run { XCUIDevice.shared.appearance = restored }
        }
        XCUIDevice.shared.appearance = appearance
    }

    /// Audits the visible viewport once and fails once per reported issue.
    @MainActor
    func assertNoAuditIssues(
        in app: XCUIApplication,
        types: XCUIAccessibilityAuditType,
        screen: String,
        variant: String,
        exemptElementKeys: Set<String> = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        var exempted = 0
        try app.performAccessibilityAudit(for: types) { issue in
            if Self.isExempt(issue, elementKeys: exemptElementKeys) {
                exempted += 1
            } else {
                Self.recordAuditIssue(issue, screen: screen, variant: variant, file: file, line: line)
            }
            // true means handled, so the system records no second failure.
            return true
        }
        if exempted > 0 {
            let note = XCTAttachment(string: "Exempted (D11-28) audit reports: \(exempted); "
                + "screen=\(screen) variant=\(variant) keys=\(exemptElementKeys.sorted())")
            note.lifetime = .keepAlways
            add(note)
        }
    }

    /// True only for a `dynamicType` or `textClipped` issue whose element key is in the explicit
    /// per-call set. Every other issue (and every other type) is a failure.
    @MainActor
    private static func isExempt(_ issue: XCUIAccessibilityAuditIssue, elementKeys: Set<String>) -> Bool {
        guard !elementKeys.isEmpty,
              issue.auditType == .dynamicType || issue.auditType == .textClipped
        else { return false }
        return elementKeys.contains(AccessibilityAuditKey.elementKey(for: issue.element))
    }

    /// Audits the launch viewport, then scrolls up to `maxPages - 1` more times and audits each
    /// new viewport. The page number is appended to the variant text ("ax5 page 2").
    @MainActor
    func assertNoAuditIssuesWhileScrolling(
        in app: XCUIApplication,
        types: XCUIAccessibilityAuditType,
        screen: String,
        variant: String,
        maxPages: Int = 4,
        exemptElementKeys: Set<String> = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        for page in 1...max(maxPages, 1) {
            let pageVariant = page == 1 ? variant : "\(variant) page \(page)"
            try assertNoAuditIssues(
                in: app, types: types, screen: screen, variant: pageVariant,
                exemptElementKeys: exemptElementKeys, file: file, line: line
            )
            guard page < maxPages else { break }
            let scrollable = [app.scrollViews, app.collectionViews, app.tables]
                .map { $0.firstMatch }
                .first { $0.exists }
            guard let scrollable else { break }
            scrollable.swipeUp()
        }
    }

    /// Narrower than `assertNoAuditIssues`: fails on audit findings, of the caller's types, that are
    /// reported for a test-only probe element, and nothing else. Findings on other elements are out of
    /// scope here and stay covered, unfiltered, by the per-screen audit classes. Every identifier in
    /// `requiredIdentifiers` must resolve first, so a missing probe never passes vacuously.
    @MainActor
    func assertNoAuditIssuesOnProbes(
        in app: XCUIApplication,
        types: XCUIAccessibilityAuditType,
        requiredIdentifiers: [String],
        identifierPrefixes: [String],
        screen: String,
        variant: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        for identifier in requiredIdentifiers {
            let found = app.descendants(matching: .any).matching(identifier: identifier).firstMatch.exists
            if !found {
                XCTFail("Probe element missing before audit: screen=\(screen) element=\(identifier)",
                        file: file, line: line)
            }
        }
        try app.performAccessibilityAudit(for: types) { issue in
            let identifier = issue.element?.identifier ?? ""
            if identifierPrefixes.contains(where: { identifier.hasPrefix($0) }) {
                Self.recordAuditIssue(issue, screen: screen, variant: variant, file: file, line: line)
            }
            return true
        }
    }

    /// Records one issue under the stable key format.
    @MainActor
    private static func recordAuditIssue(
        _ issue: XCUIAccessibilityAuditIssue,
        screen: String,
        variant: String,
        file: StaticString,
        line: UInt
    ) {
        let typeName = AccessibilityAuditKey.typeName(for: issue.auditType)
        let elementKey = AccessibilityAuditKey.elementKey(for: issue.element)
        XCTFail("Accessibility audit issue: "
                + "screen=\(screen) variant=\(variant) "
                + "type=\(typeName) element=\(elementKey)",
                file: file, line: line)
    }
}
