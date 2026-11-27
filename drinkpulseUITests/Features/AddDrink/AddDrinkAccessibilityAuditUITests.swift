import XCTest

/// Ungated accessibility audit of the Add Drink sheet: step 1, the type list (plan 11-18, then
/// plan 0047), and step 2, the serving form (plan 0047, Task 6).
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
    private func launchAndOpenAddDrink(
        contentSizeCategory: String?, appearance: XCUIDevice.Appearance = .light
    ) -> XCUIApplication? {
        pinAppearance(appearance)
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
        try assertNoAuditIssues(in: app, types: .all, screen: "Add Drink", variant: "standard",
                                exemptSystemControl: AuditSearchField.exemption)
    }

    func test_addDrink_ax5_hasNoAuditIssues() throws {
        guard let app = launchAndOpenAddDrink(contentSizeCategory: AuditLaunch.ax5Category) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Add Drink", variant: "ax5",
                                exemptSystemControl: AuditSearchField.exemption)
    }

    func test_addDrink_dark_hasNoAuditIssues() throws {
        guard let app = launchAndOpenAddDrink(contentSizeCategory: nil, appearance: .dark) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Add Drink", variant: "dark",
                                exemptSystemControl: AuditSearchField.exemption)
    }

    // MARK: - Step 2

    /// Opens Wine's step 2; the Wine row sits below the fold at AX5.
    private func openStep2(in app: XCUIApplication) -> Bool {
        let wine = app.buttons["addDrink.type.wine"]
        for _ in 0..<6 where !(wine.exists && wine.isHittable) { app.swipeUp() }
        guard wine.waitForExistence(timeout: 10) else {
            XCTFail("Wine row should exist")
            return false
        }
        wine.tap()
        let shown = app.navigationBars["Wine"].waitForExistence(timeout: 10)
        XCTAssertTrue(shown, "Wine step 2 should be shown")
        return shown
    }

    func test_addDrinkStep2_standard_hasNoAuditIssues() throws {
        guard let app = launchAndOpenAddDrink(contentSizeCategory: nil), openStep2(in: app) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Add Drink step 2", variant: "standard")
    }

    func test_addDrinkStep2_dark_hasNoAuditIssues() throws {
        guard let app = launchAndOpenAddDrink(contentSizeCategory: nil, appearance: .dark),
              openStep2(in: app) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Add Drink step 2", variant: "dark")
    }

    func test_addDrinkStep2_ax5_hasNoAuditIssues() throws {
        guard let app = launchAndOpenAddDrink(contentSizeCategory: AuditLaunch.ax5Category),
              openStep2(in: app) else { return }
        // Owner decision D11-28: at AX5 the system Form picker rows (Volume, Strength, Amount)
        // report `dynamicType` / `textClipped` though they use default text styles; exactly
        // these keys are tolerated for those two types (same set as AddDrinkDynamicTypeUITests).
        try assertNoAuditIssues(in: app, types: .all, screen: "Add Drink step 2", variant: "ax5",
                                exemptElementKeys: ["Volume", "Strength", "Amount", "none#type=nil"])
    }
}
