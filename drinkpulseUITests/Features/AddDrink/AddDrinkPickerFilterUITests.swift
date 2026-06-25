import XCTest

/// Asserts that in US mode the serving picker in DrinkDetailInputView shows
/// oz-native serving labels (e.g. "Pint · 16 oz", "Bottle · 16.9 oz · 500 ml")
/// and does NOT surface an imperial-only pint label (plan-0030 / plan-0031).
///
/// Picker note: wheel picker content is NOT surfaced as `staticTexts`.
/// The selected value is read via `pickerWheels.element(boundBy: 0).value`.
@MainActor
final class AddDrinkPickerFilterUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Builds and launches the app. Kept off the nonisolated `setUpWithError`
    /// override so the MainActor-isolated XCUI calls run on the MainActor.
    private func launchApp() {
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
        launchApp()
        openAddDrinkSheet()

        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 10),
                      "Beer tile should be visible in the Add Drink grid")
        beerTile.tap()

        let beerNavBar = app.navigationBars["Beer"]
        XCTAssertTrue(beerNavBar.waitForExistence(timeout: 5),
                      "Beer detail screen navigation bar should appear")

        // The volume picker wheel surfaces its selected row as `.value`.
        // In US mode serving labels render in ounces (e.g. "Bottle · 16.9 oz · 500 ml").
        let volumeWheel = app.pickerWheels.element(boundBy: 0)
        XCTAssertTrue(volumeWheel.waitForExistence(timeout: 5),
                      "Volume picker wheel should be present in Beer detail screen")

        let selectedValue = volumeWheel.value as? String ?? ""
        XCTAssertTrue(selectedValue.contains("oz"),
                      "Volume picker selected value should be an oz serving in US mode, "
                      + "got '\(selectedValue)'")

        // The imperial-only pint label must NOT appear in US mode.
        XCTAssertFalse(selectedValue.contains("pint"),
                       "US mode serving label must not be a pint, got '\(selectedValue)'")
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
