import XCTest

/// Ungated accessibility audit of the History tab.
///
/// Two `dynamicType`-only tests prove audit group A11Y-AUDIT-G08 (the test-only Health sample-count
/// probe reported as a 1 point text) is detectable and, after the fix, closed. Three all-types tests
/// (plan 11-21: default size, dark appearance and AX5, launch viewport) cover every audit type and
/// the History share of group A11Y-AUDIT-G09. They pass one explicit, key-scoped opt-in (owner decision
/// D11-31, ledger DL-O21): an element-less `contrast` issue is not evaluated while the tab bar is shown,
/// because it is a system tab-bar glass artifact (the issue disappears when the tab bar is hidden).
/// Each ignored issue is logged as a warning; every other issue fails. Unlike `AccessibilityAuditUITests` the class is not
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
        try assertNoAuditIssues(in: app, types: [.dynamicType], screen: "History", variant: "ax5",
                                exemptElementKeys: AuditBarControls.keys)
    }

    func test_history_standard_hasNoAuditIssues() throws {
        guard let app = launchAndOpenHistory(contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "History", variant: "standard",
                                ignoreTabBarOccludedContent: true,
                                ignoreTabBarElementlessContrast: true,
                                exemptSystemControl: HistoryAuditSystemControls.exemption(in: app))
    }

    func test_history_dark_hasNoAuditIssues() throws {
        guard let app = launchAndOpenHistory(appearance: .dark, contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "History", variant: "dark",
                                ignoreTabBarOccludedContent: true,
                                ignoreTabBarElementlessContrast: true,
                                exemptSystemControl: HistoryAuditSystemControls.exemption(in: app))
    }

    func test_history_ax5_hasNoAuditIssues() throws {
        guard let app = launchAndOpenHistory(contentSizeCategory: AuditLaunch.ax5Category) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "History", variant: "ax5",
                                exemptElementKeys: AuditBarControls.keys,
                                ignoreTabBarOccludedContent: true,
                                ignoreTabBarElementlessContrast: true,
                                exemptSystemControl: HistoryAuditSystemControls.exemption(in: app))
    }

    // MARK: - Calendar mode (plan 0045, Task 6)

    private func openCalendar(in app: XCUIApplication) -> Bool {
        let segment = app.navigationBars.segmentedControls.buttons["Calendar"]
        guard segment.waitForExistence(timeout: 5) else {
            XCTFail("Calendar segment should exist")
            return false
        }
        segment.tap()
        let calendar = app.descendants(matching: .any)["history.calendar"]
        let shown = calendar.waitForExistence(timeout: 10)
        XCTAssertTrue(shown, "The calendar should be shown")
        // Let the calendar finish its first layout before the audit snapshots the tree.
        _ = app.buttons["history.calendar.today"].waitForExistence(timeout: 1)
        return shown
    }

    func test_historyCalendar_standard_hasNoAuditIssues() throws {
        guard let app = launchAndOpenHistory(contentSizeCategory: nil), openCalendar(in: app) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "HistoryCalendar", variant: "standard",
                                ignoreTabBarOccludedContent: true,
                                ignoreTabBarElementlessContrast: true,
                                exemptSystemControl: HistoryAuditSystemControls.exemption(in: app, calendar: true))
    }

    func test_historyCalendar_ax5_hasNoAuditIssues() throws {
        guard let app = launchAndOpenHistory(contentSizeCategory: AuditLaunch.ax5Category),
              openCalendar(in: app) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "HistoryCalendar", variant: "ax5",
                                exemptElementKeys: AuditBarControls.keys,
                                ignoreTabBarOccludedContent: true,
                                ignoreTabBarElementlessContrast: true,
                                exemptSystemControl: HistoryAuditSystemControls.exemption(in: app, calendar: true))
    }
}
