import XCTest

/// Ungated accessibility audit of Edit Drink, pushed inside History (plan 0047, Task 6): the
/// launch viewport with every audit type, standard, dark and AX5. Every reported issue fails.
@MainActor
final class EditDrinkAccessibilityAuditUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// Opens Edit Drink on the first seeded row, or returns nil after a recorded failure.
    private func launchAndOpenEdit(
        contentSizeCategory: String?, appearance: XCUIDevice.Appearance = .light
    ) -> XCUIApplication? {
        pinAppearance(appearance)
        let app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(onboarding: false, contentSizeCategory: contentSizeCategory)
        app.launch()
        let tab = app.tabBars.buttons["History"]
        guard tab.waitForExistence(timeout: 15) else {
            XCTFail("History tab should exist")
            return nil
        }
        tab.tap()
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "logged at")).firstMatch
        guard row.waitForExistence(timeout: 10) else {
            XCTFail("A seeded History row should exist")
            return nil
        }
        row.tap()
        let shown = app.navigationBars["Edit Drink"].waitForExistence(timeout: 10)
        XCTAssertTrue(shown, "Edit Drink should be shown")
        return shown ? app : nil
    }

    func test_editDrink_standard_hasNoAuditIssues() throws {
        guard let app = launchAndOpenEdit(contentSizeCategory: nil) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Edit Drink", variant: "standard",
                                ignoreTabBarOccludedContent: true)
    }

    func test_editDrink_dark_hasNoAuditIssues() throws {
        guard let app = launchAndOpenEdit(contentSizeCategory: nil, appearance: .dark) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Edit Drink", variant: "dark",
                                ignoreTabBarOccludedContent: true)
    }

    func test_editDrink_ax5_hasNoAuditIssues() throws {
        guard let app = launchAndOpenEdit(contentSizeCategory: AuditLaunch.ax5Category) else { return }
        try assertNoAuditIssues(in: app, types: .all, screen: "Edit Drink", variant: "ax5",
                                ignoreTabBarOccludedContent: true)
    }
}
