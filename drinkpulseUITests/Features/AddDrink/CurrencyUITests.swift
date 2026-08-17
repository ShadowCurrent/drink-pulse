import XCTest

@MainActor
final class CurrencyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        app.launch()
    }

    func test_currencyControl_defaultsToProfile_andFollowsSelection() throws {
        launchApp()
        openBeerDetail()

        let currency = currencyControl()
        XCTAssertTrue(currency.waitForExistence(timeout: 5),
                      "Currency control should be present in the price row")
        XCTAssertEqual(currency.value as? String, "USD",
                       "Currency should default to the profile currency (USD)")

        currency.tap()
        let euro = app.buttons["EUR · €"]
        XCTAssertTrue(euro.waitForExistence(timeout: 3),
                      "EUR option should appear in the currency menu")
        euro.tap()

        XCTAssertEqual(currencyControl().value as? String, "EUR",
                       "Currency control should follow the menu selection to EUR")
    }

    func test_settingsCurrency_becomesAddDefault() throws {
        launchApp()

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Settings should open")
        let currencyRow = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Currency, '")
        ).firstMatch
        if !currencyRow.waitForExistence(timeout: 5) { app.swipeUp() }
        XCTAssertTrue(currencyRow.waitForExistence(timeout: 5),
                      "Settings currency picker should be visible")
        currencyRow.tap()
        let gbp = app.buttons["GBP · £"]
        XCTAssertTrue(gbp.waitForExistence(timeout: 3),
                      "GBP option should appear in the Settings currency menu")
        gbp.tap()

        openBeerDetail()
        let currency = currencyControl()
        XCTAssertTrue(currency.waitForExistence(timeout: 5),
                      "Currency control should be present in the price row")
        XCTAssertEqual(currency.value as? String, "GBP",
                       "Add form should seed the profile currency (GBP) as default")
    }

    // MARK: - Helpers

    private func openBeerDetail() {
        let home = app.tabBars.buttons["Home"]
        XCTAssertTrue(home.waitForExistence(timeout: 10), "Home tab should be accessible")
        home.tap()
        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add Drink button should be visible")
        addButton.tap()
        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 10), "Beer tile should be visible")
        beerTile.tap()
        XCTAssertTrue(app.navigationBars["Beer"].waitForExistence(timeout: 5),
                      "Beer detail screen should appear")
    }

    private func currencyControl() -> XCUIElement {
        let control = app.buttons["Currency"]
        if !control.waitForExistence(timeout: 3) { app.swipeUp() }
        return app.buttons["Currency"]
    }
}
