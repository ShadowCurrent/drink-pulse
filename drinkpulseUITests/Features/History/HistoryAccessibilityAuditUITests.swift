import XCTest

/// Ungated accessibility audit of the History tab.
///
/// Two `dynamicType`-only tests prove audit group A11Y-AUDIT-G08 (the test-only Health sample-count
/// probe reported as a 1 point text) is detectable and, after the fix, closed. Three all-types tests
/// (plan 11-21: default size, dark appearance and AX5, launch viewport) cover every audit type and
/// the History share of group A11Y-AUDIT-G09. Unlike `AccessibilityAuditUITests` the class is not
/// gated: it runs in the normal suite. Every reported issue fails the test.
@MainActor
final class HistoryAccessibilityAuditUITests: XCTestCase {

    override func setUpWithError() throws {
        // Collect every issue of a pass; each is its own failure.
        continueAfterFailure = true
    }

    private func launchAndOpenHistory(
        appearance: XCUIDevice.Appearance = .light,
        contentSizeCategory: String?
    ) -> XCUIApplication? {
        pinAppearance(appearance)
        let app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(onboarding: false, contentSizeCategory: contentSizeCategory)
        app.launch()
        let tab = app.tabBars.buttons["History"]
        let hasTab = tab.waitForExistence(timeout: 15)
        XCTAssertTrue(hasTab, "History tab should exist")
        guard hasTab else { return nil }
        tab.tap()
        let shown = app.navigationBars["History"].waitForExistence(timeout: 10)
        XCTAssertTrue(shown, "History screen should be shown")
        return shown ? app : nil
    }

    func test_history_standardSize_hasNoDynamicTypeIssues() throws {
        guard let app = launchAndOpenHistory(contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(in: app, types: [.dynamicType], screen: "History", variant: "standard")
    }

    func test_history_ax5_hasNoDynamicTypeIssues() throws {
        guard let app = launchAndOpenHistory(contentSizeCategory: AuditLaunch.ax5Category) else { return }
        try assertNoAuditIssues(in: app, types: [.dynamicType], screen: "History", variant: "ax5")
    }

    func test_history_standard_hasNoAuditIssues() throws {
        guard let app = launchAndOpenHistory(contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "History", variant: "standard")
    }

    func test_history_dark_hasNoAuditIssues() throws {
        guard let app = launchAndOpenHistory(appearance: .dark, contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "History", variant: "dark")
    }

    func test_history_ax5_hasNoAuditIssues() throws {
        guard let app = launchAndOpenHistory(contentSizeCategory: AuditLaunch.ax5Category) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "History", variant: "ax5")
    }
}
