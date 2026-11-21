import XCTest

/// Ungated accessibility audit of the Add Drink sheet, step 1 (plan 11-18, audit groups
/// A11Y-AUDIT-G01 drink-type tiles and G02 Cancel button).
///
/// Audits the launch viewport of the sheet with every audit type, the same coverage as the gated
/// `AccessibilityAuditUITests` Add Drink methods, at the default text size and at AX5, both in
/// light appearance. It runs in the normal suite and every reported issue fails the test. The sheet
/// covers the tab bar, so the D11-29 opt-in does not apply and is not used.
@MainActor
final class AddDrinkAccessibilityAuditUITests: XCTestCase {

    override func setUpWithError() throws {
        // Collect every issue of a pass; each is its own failure.
        continueAfterFailure = true
    }

    /// Returns the app with the Add Drink sheet shown, or nil (after a recorded failure) when
    /// navigation fails, so a navigation failure never reaches the audit.
    private func launchAndOpenAddDrink(contentSizeCategory: String?) -> XCUIApplication? {
        pinAppearance(.light)
        let app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(onboarding: false, contentSizeCategory: contentSizeCategory)
        app.launch()
        let tab = app.tabBars.buttons[UITestTabs.today]
        let hasTab = tab.waitForExistence(timeout: 15)
        XCTAssertTrue(hasTab, "Home tab should exist")
        guard hasTab else { return nil }
        tab.tap()
        let add = app.buttons["Add Drink"]
        let hasAdd = add.waitForExistence(timeout: 10)
        XCTAssertTrue(hasAdd, "Add Drink button should exist on Home")
        guard hasAdd else { return nil }
        add.tap()
        let shown = app.navigationBars["Add Drink"].waitForExistence(timeout: 10)
        XCTAssertTrue(shown, "Add Drink sheet should be shown")
        return shown ? app : nil
    }

    func test_addDrink_standard_hasNoAuditIssues() throws {
        guard let app = launchAndOpenAddDrink(contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Add Drink", variant: "standard")
    }

    func test_addDrink_ax5_hasNoAuditIssues() throws {
        guard let app = launchAndOpenAddDrink(contentSizeCategory: AuditLaunch.ax5Category) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Add Drink", variant: "ax5")
    }
}
