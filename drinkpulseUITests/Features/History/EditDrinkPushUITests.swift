import XCTest

/// Edit Drink pushed inside History (plan 0047, D0047-8 / D0047-9). The `-dp_uitest` store
/// holds one seeded 500 ml beer.
@MainActor
final class EditDrinkPushUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        app.launch()
    }

    func test_tapRow_pushesEditDrink_withBackButton() throws {
        launch()
        openEdit()
        XCTAssertTrue(editBar.buttons["BackButton"].waitForExistence(timeout: 5),
                      "Edit Drink is pushed: the system Back button is shown")
        XCTAssertTrue(app.tabBars.buttons["History"].exists,
                      "A pushed Edit keeps the tab bar")
    }

    func test_save_popsToHistory_andShowsChange() throws {
        launch()
        openEdit()
        let name = app.textFields["Custom Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Pushed Edit")
        app.buttons["drinkForm.confirm"].tap()

        XCTAssertTrue(editBar.waitForNonExistence(timeout: 5), "Saving pops back to History")
        XCTAssertTrue(row(containing: "Pushed Edit").waitForExistence(timeout: 5),
                      "History shows the saved change")
    }

    func test_logAgain_logsStoredDrink_discardsEdits() throws {
        launch()
        openEdit()
        let amount = app.pickerWheels.element(boundBy: 2)
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.adjust(toPickerWheelValue: "3×")
        XCTAssertEqual(amount.value as? String, "3×")

        tapInForm(app.buttons["editDrink.logAgain"])

        XCTAssertTrue(editBar.waitForNonExistence(timeout: 5), "Log Again pops back to History")
        XCTAssertTrue(waitForRowCount("500 ml", 2), "Log Again adds one copy of the stored drink")
        XCTAssertEqual(rowCount("×3"), 0, "The unsaved count change is discarded")
    }

    func test_deleteDrink_confirms_thenPops() throws {
        launch()
        openEdit()
        tapInForm(app.buttons["editDrink.delete"])
        let confirm = app.buttons["confirmDeleteButton"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Delete Drink asks for confirmation")
        confirm.tap()

        XCTAssertTrue(editBar.waitForNonExistence(timeout: 5), "Deleting pops back to History")
        XCTAssertTrue(waitForRowCount("500 ml", 0), "The deleted drink leaves History")
    }

    func test_changeType_showsCheckmarkOnCurrent() throws {
        launch()
        openEdit()
        let typeRow = app.buttons["editDrink.typeRow"]
        XCTAssertTrue(typeRow.waitForExistence(timeout: 5))
        typeRow.tap()
        XCTAssertTrue(app.navigationBars["Change Type"].waitForExistence(timeout: 5),
                      "Tapping Type pushes the type list")
        let beer = app.buttons["addDrink.type.beer"]
        XCTAssertTrue(beer.waitForExistence(timeout: 5))
        XCTAssertTrue(beer.isSelected, "The current type is marked selected")
        XCTAssertFalse(app.buttons["addDrink.type.wine"].isSelected)

        beer.tap()
        XCTAssertTrue(editBar.waitForExistence(timeout: 5), "Choosing a type returns to Edit")
    }

    // MARK: - Helpers

    private var editBar: XCUIElement { app.navigationBars["Edit Drink"] }

    private func openEdit() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()
        let beer = row(containing: "500 ml")
        XCTAssertTrue(beer.waitForExistence(timeout: 10), "Seeded beer row should be listed")
        beer.tap()
        XCTAssertTrue(editBar.waitForExistence(timeout: 5), "Tapping a row opens Edit Drink")
    }

    /// The Log Again and Delete rows sit at the bottom of the form. The drag starts low on the
    /// screen: a swipe from the centre lands on the serving wheels and turns them instead.
    private func tapInForm(_ element: XCUIElement) {
        for _ in 0..<6 where !isOnScreen(element) {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
            start.press(forDuration: 0.05, thenDragTo: app.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)))
            usleep(800_000) // let the scroll settle before reading frames
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(element) should be in the form")
        element.tap()
    }

    /// `isHittable` throws for a lazy row that is not laid out yet, so check the frame.
    private func isOnScreen(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        let window = app.windows.firstMatch.frame
        return element.frame.minY > window.minY + 120 && element.frame.maxY < window.maxY - 100
    }

    private func row(containing substring: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
    }

    private func rowCount(_ substring: String) -> Int {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).count
    }

    private func waitForRowCount(_ substring: String, _ expected: Int) -> Bool {
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if rowCount(substring) == expected { return true }
            usleep(150_000)
        }
        return rowCount(substring) == expected
    }
}
