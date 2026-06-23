import XCTest

/// Asserts that in US mode the serving picker in DrinkDetailInputView shows
/// oz-native values (e.g. "US pint · 16.0 fl oz") and does NOT include
/// metric-only rows (500 ml Bottle) or imperial-only rows (Pint 20.0 fl oz)
/// as the selected default (plan-0030).
///
/// Picker note: wheel picker content is NOT surfaced as `staticTexts`.
/// The selected value is read via `pickerWheels.element(boundBy: 0).value`.
final class AddDrinkPickerFilterUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "usCustomary",
        ]
        app.launch()
    }

    /// Opens Add Drink → Beer, reads the volume picker wheel's selected value,
    /// and asserts it shows a US-native fl oz value.  Also asserts that the
    /// metric-only "Bottle · 500 ml" and imperial-only "Pint · 20.0 fl oz"
    /// entries do not appear as the selected value.
    func test_addBeer_usMode_showsFlOzLabels() throws {
        openAddDrinkSheet()

        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 10),
                      "Beer tile should be visible in the Add Drink grid")
        beerTile.tap()

        let beerNavBar = app.navigationBars["Beer"]
        XCTAssertTrue(beerNavBar.waitForExistence(timeout: 5),
                      "Beer detail screen navigation bar should appear")

        // The volume picker wheel surfaces its selected row as `.value`.
        // In US mode the default is "US pint · 16.0 fl oz" or "US can · 12.0 fl oz".
        let volumeWheel = app.pickerWheels.element(boundBy: 0)
        XCTAssertTrue(volumeWheel.waitForExistence(timeout: 5),
                      "Volume picker wheel should be present in Beer detail screen")

        let selectedValue = volumeWheel.value as? String ?? ""
        XCTAssertTrue(selectedValue.contains("fl oz"),
                      "Volume picker selected value should contain 'fl oz' in US mode, "
                      + "got '\(selectedValue)'")

        // The metric-only Bottle (500 ml) must NOT be the selected value.
        XCTAssertFalse(selectedValue.contains("500 ml"),
                       "US mode default must not be the metric 500 ml Bottle, "
                       + "got '\(selectedValue)'")

        // The imperial-only Pint (20.0 fl oz / 568 ml) must NOT be selected.
        XCTAssertFalse(selectedValue.contains("20.0"),
                       "US mode default must not be the imperial 20.0 fl oz Pint, "
                       + "got '\(selectedValue)'")
    }

    // MARK: - Helpers

    private func openAddDrinkSheet() {
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Home tab should be accessible after launch")

        // AddDrinkButton has accessibilityLabel = "Add Drink" (addDrink.title).
        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "Add Drink button should be visible after launch")
        addButton.tap()

        let addNavBar = app.navigationBars["Add Drink"]
        XCTAssertTrue(addNavBar.waitForExistence(timeout: 5),
                      "Add Drink navigation bar should appear")
    }
}
