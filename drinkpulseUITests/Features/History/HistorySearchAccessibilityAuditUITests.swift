import XCTest

/// Accessibility audit of the History List search while it is in use (plan-0039).
///
/// `HistoryAccessibilityAuditUITests` audits the idle screen only. These tests
/// focus the inline search field and type a query, so the Cancel button, the
/// clear button, the scope picker and the no-matches empty state are audited
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
        let field = app.descendants(matching: .any)["history.search.field"]
        guard field.waitForExistence(timeout: 10) else {
            XCTFail("History search field should exist")
            return nil
        }
        field.tap()
        field.typeText("zz")
        XCTAssertTrue(app.buttons["history.search.clear"].waitForExistence(timeout: 5),
                      "Clear button should show for a non-empty query")
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5),
                      "Cancel should show while the field is focused")
        return app
    }

    func test_historySearch_active_standard_hasNoAuditIssues() throws {
        guard let app = launchWithActiveSearch(contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "HistorySearch", variant: "standard",
                                ignoreTabBarElementlessContrast: true)
    }

    func test_historySearch_active_ax5_hasNoAuditIssues() throws {
        guard let app = launchWithActiveSearch(contentSizeCategory: AuditLaunch.ax5Category) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "HistorySearch", variant: "ax5",
                                ignoreTabBarElementlessContrast: true)
    }
}
