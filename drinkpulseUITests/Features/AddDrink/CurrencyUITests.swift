import XCTest

/// UI coverage for the per-event currency control (plan-0034).
///
/// Verifies the two user-visible outcomes the feature promises:
/// - the Add form's price row exposes a **currency** control that defaults to
///   the profile currency and whose selection follows a menu pick;
/// - changing the **profile currency in Settings** changes the default the Add
///   form seeds into a freshly-opened drink.
///
/// The currency control is a SwiftUI `.menu` `Picker` sharing the price row,
/// with `accessibilityLabel` "Currency" and `accessibilityValue` set to the
/// selected ISO code, so the selection is read via the button's `.value` —
/// locale-independent (the app is English-only; codes like "USD"/"EUR" are not
/// localized). Menu options read "<code> · <symbol>".
///
/// Seed: `-dp_uitest YES` provides a profile whose currency defaults to "USD".
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

    /// The currency control defaults to the profile currency (USD) and updates
    /// when a different option is picked from its menu.
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

    /// Changing the profile currency in Settings becomes the default a newly
    /// opened Add form seeds.
    func test_settingsCurrency_becomesAddDefault() throws {
        launchApp()

        // Change the profile currency to GBP in Settings.
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

        // A freshly opened Add form should seed GBP as the currency default.
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

    /// The currency `.menu` control (a button labelled "Currency"). Scrolls the
    /// form up if the price row sits below the fold.
    private func currencyControl() -> XCUIElement {
        let control = app.buttons["Currency"]
        if !control.waitForExistence(timeout: 3) { app.swipeUp() }
        return app.buttons["Currency"]
    }
}
