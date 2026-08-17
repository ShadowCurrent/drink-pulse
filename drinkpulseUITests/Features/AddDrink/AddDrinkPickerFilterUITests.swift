import XCTest

@MainActor
final class AddDrinkPickerFilterUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "usCustomary",
        ]
        app.launch()
    }

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

        let volumeWheel = app.pickerWheels.element(boundBy: 0)
        XCTAssertTrue(volumeWheel.waitForExistence(timeout: 5),
                      "Volume picker wheel should be present in Beer detail screen")

        let selectedValue = volumeWheel.value as? String ?? ""
        XCTAssertTrue(selectedValue.contains("oz"),
                      "Volume picker selected value should be an oz serving in US mode, "
                      + "got '\(selectedValue)'")

        XCTAssertFalse(selectedValue.contains("pint"),
                       "US mode serving label must not be a pint, got '\(selectedValue)'")
    }

    // MARK: - Helpers

    private func openAddDrinkSheet() {
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Home tab should be accessible after launch")

        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "Add Drink button should be visible after launch")
        addButton.tap()

        let addNavBar = app.navigationBars["Add Drink"]
        XCTAssertTrue(addNavBar.waitForExistence(timeout: 5),
                      "Add Drink navigation bar should appear")
    }
}
