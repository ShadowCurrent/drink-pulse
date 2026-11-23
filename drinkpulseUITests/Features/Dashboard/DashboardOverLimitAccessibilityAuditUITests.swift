import XCTest

/// Ungated Dark audit of Home with today over the daily limit (plan 0042 final review).
///
/// The `multiday` seed keeps today under the limit, so the hero "Exceeded" label and the
/// exceeded tone on the hero never reach `DashboardAccessibilityAuditUITests`. This class logs one
/// more beer through the real Add Drink flow to push today over the limit, then audits Dark, where
/// the plan 0042 risk tone is darker than the old risk text colour.
@MainActor
final class DashboardOverLimitAccessibilityAuditUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func test_home_dark_overLimit_hasNoAuditIssues() throws {
        pinAppearance(.dark)
        let app = XCUIApplication()
        app.launchArguments += AuditLaunch.arguments(onboarding: false, contentSizeCategory: nil)
        app.launch()

        let tab = app.tabBars.buttons[UITestTabs.today]
        XCTAssertTrue(tab.waitForExistence(timeout: 15), "Home tab should exist")
        tab.tap()
        XCTAssertTrue(app.navigationBars[UITestTabs.today].waitForExistence(timeout: 10), "Home should be shown")

        logBeer(in: app)

        // The hero is one combined element; its label carries today's status (plan 0046, D0046-2).
        let overLimit = app.descendants(matching: .any)["today.hero"]
        XCTAssertTrue(overLimit.waitForExistence(timeout: 10) && overLimit.label.contains("Over Limit"),
                      "Today should be over the daily limit after logging a second beer")

        try assertNoAuditIssues(
            in: app, types: .all, screen: UITestTabs.today, variant: "dark-overLimit", ignoreTabBarOccludedContent: true,
            ignoreTabBarElementlessContrast: true // D11-31 (plan 0046 Task 7)
        )
    }

    private func logBeer(in app: XCUIApplication) {
        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add Drink button should be present")
        addButton.tap()
        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 5), "Beer row should be visible")
        beerTile.tap()
        let save = app.buttons["drinkForm.confirm"]
        XCTAssertTrue(save.waitForExistence(timeout: 5), "Beer detail should have the confirm button")
        save.tap()
        XCTAssertTrue(app.navigationBars[UITestTabs.today].waitForExistence(timeout: 5), "Saving should return Home")
    }
}
