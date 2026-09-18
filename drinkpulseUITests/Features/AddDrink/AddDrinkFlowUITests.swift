import XCTest

@MainActor
final class AddDrinkFlowUITests: XCTestCase {
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

    // MARK: - Drink-type grid shows categories

    func test_drinkTypeGrid_showsCategories() throws {
        launchApp()
        openAddDrinkSheet()

        for category in ["Beer", "Wine", "Cider", "Vodka", "Whiskey", "Cocktail"] {
            let tile = app.buttons[category]
            XCTAssertTrue(tile.waitForExistence(timeout: 5),
                          "Drink-type grid should show a '\(category)' category tile")
        }
    }

    // MARK: - Full log flow: open → category → detail → Save → History

    func test_fullLogFlow_savedEvent_appearsInHistory() throws {
        launchApp()
        openAddDrinkSheet()

        let wineTile = app.buttons["Wine"]
        XCTAssertTrue(wineTile.waitForExistence(timeout: 10),
                      "Wine tile should be visible in the Add Drink grid")
        wineTile.tap()

        XCTAssertTrue(app.navigationBars["Wine"].waitForExistence(timeout: 5),
                      "Wine detail screen navigation bar should appear")

        let customName = "Barolo Riserva"
        typeCustomName(customName)
        save(on: "Wine")

        openHistoryTab()
        let savedRow = eventButton(containing: customName)
        XCTAssertTrue(savedRow.waitForExistence(timeout: 10),
                      "The newly-logged '\(customName)' event should appear in History")
    }

    // MARK: - Quantity ×N control changes the logged count

    func test_quantityControl_logsMultiplePortions_showsTimesNInHistory() throws {
        launchApp()
        openAddDrinkSheet()

        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 10),
                      "Beer tile should be visible in the Add Drink grid")
        beerTile.tap()
        XCTAssertTrue(app.navigationBars["Beer"].waitForExistence(timeout: 5),
                      "Beer detail screen navigation bar should appear")

        let amountWheel = app.pickerWheels.element(boundBy: 2)
        XCTAssertTrue(amountWheel.waitForExistence(timeout: 5),
                      "Amount (quantity) picker wheel should be present")
        amountWheel.adjust(toPickerWheelValue: "2×")
        XCTAssertEqual(amountWheel.value as? String, "2×",
                       "Amount wheel should now read '2×'")

        save(on: "Beer")

        openHistoryTab()
        let multiRow = eventButton(containing: "×2")
        XCTAssertTrue(multiRow.waitForExistence(timeout: 10),
                      "A 2-portion beer should appear in History with a '×2' suffix")
    }

    // MARK: - Custom name path

    func test_customName_isRenderedInHistory() throws {
        launchApp()
        openAddDrinkSheet()

        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 10),
                      "Beer tile should be visible in the Add Drink grid")
        beerTile.tap()
        XCTAssertTrue(app.navigationBars["Beer"].waitForExistence(timeout: 5),
                      "Beer detail screen navigation bar should appear")

        let customName = "Hazy Session IPA"
        typeCustomName(customName)
        save(on: "Beer")

        openHistoryTab()
        XCTAssertTrue(eventButton(containing: customName).waitForExistence(timeout: 10),
                      "The custom name '\(customName)' should be rendered for the logged event")
    }

    // MARK: - Sheet dismissal preserves originating tab

    func test_originatingHistoryTab_gridCancel_returnsToHistory() throws {
        launchApp()
        openAddDrinkSheet(from: "History")

        let cancel = app.navigationBars["Add Drink"].buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "Cancel should be discoverable before dismissal")
        cancel.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5),
                      "Grid cancel should return to the originating History tab")
    }

    func test_originatingSettingsTab_save_persistsAndReturnsToSettings() throws {
        launchApp()
        openAddDrinkSheet(from: "Settings")

        let beer = app.buttons["Beer"]
        XCTAssertTrue(beer.waitForExistence(timeout: 5))
        beer.tap()
        XCTAssertTrue(app.navigationBars["Beer"].waitForExistence(timeout: 5))
        typeCustomName("Originating tab save")
        save(on: "Beer")

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Saving should return to the originating Settings tab")
        openHistoryTab()
        XCTAssertTrue(eventButton(containing: "Originating tab save").waitForExistence(timeout: 10),
                      "Saving should persist the uniquely named event in History")
    }

    // MARK: - Helpers

    private func openAddDrinkSheet() {
        openAddDrinkSheet(from: "Home")
    }

    private func openAddDrinkSheet(from tabName: String) {
        let tab = app.tabBars.buttons[tabName]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "\(tabName) tab should be accessible after launch")
        tab.tap()
        XCTAssertTrue(app.navigationBars[tabName].waitForExistence(timeout: 5))

        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "Add Drink button should be visible after launch")
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5),
                      "Add Drink navigation bar should appear")
    }

    private func typeCustomName(_ text: String) {
        let field = app.textFields["Custom Name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5),
                      "Custom Name text field should be present in the detail screen")
        field.tap()
        field.typeText(text)
    }

    private func save(on detailTitle: String) {
        let saveButton = app.navigationBars[detailTitle].buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5),
                      "Save button should be present on the \(detailTitle) detail screen")
        saveButton.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5),
                      "Saving should dismiss the Add Drink sheet")
    }

    private func openHistoryTab() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should be accessible")
        tab.tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5),
                      "History screen should appear")
    }

    private func eventButton(containing substring: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
    }
}
