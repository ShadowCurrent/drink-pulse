import XCTest

/// Accessibility audit of the History List search while it is in use (plan-0039).
///
/// `HistoryAccessibilityAuditUITests` audits the idle screen only. These tests
/// focus the native search field (plan 0045) and type a query, so the Cancel button,
/// the clear button, the scope bar and the no-matches empty state are audited
/// too, at the default size and at AX5. Same opt-in as the idle audit: the
/// element-less tab-bar glass `contrast` artifact is not evaluated (D11-31).
@MainActor
final class HistorySearchAccessibilityAuditUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func launchWithActiveSearch(contentSizeCategory: String?) -> XCUIApplication? {
        pinAppearance(.light)
        let app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(onboarding: false, contentSizeCategory: contentSizeCategory)
        app.launch()
        let tab = app.tabBars.buttons["History"]
        guard tab.waitForExistence(timeout: 15) else {
            XCTFail("History tab should exist")
            return nil
        }
        tab.tap()
        let field = app.searchFields.firstMatch
        guard field.waitForExistence(timeout: 10) else {
            XCTFail("History search field should exist")
            return nil
        }
        field.tap()
        field.typeText("zz")
        // System controls matched by element type, never by label (Polish simulator locale).
        XCTAssertTrue(field.buttons.firstMatch.waitForExistence(timeout: 5),
                      "Clear button should show for a non-empty query")
        return app
    }

    func test_historySearch_active_standard_hasNoAuditIssues() throws {
        guard let app = launchWithActiveSearch(contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "HistorySearch", variant: "standard",
                                ignoreTabBarOccludedContent: true,
                                ignoreTabBarElementlessContrast: true,
                                exemptSystemControl: HistoryAuditSystemControls.exemption(in: app))
    }

    func test_historySearch_active_ax5_hasNoAuditIssues() throws {
        guard let app = launchWithActiveSearch(contentSizeCategory: AuditLaunch.ax5Category) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "HistorySearch", variant: "ax5",
                                ignoreTabBarOccludedContent: true,
                                ignoreTabBarElementlessContrast: true,
                                exemptSystemControl: HistoryAuditSystemControls.exemption(in: app))
    }
}
