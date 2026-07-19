import XCTest

/// End-to-end coverage for the Custom Name tap-to-autocomplete suggestion list
/// (`CustomNameSuggestionSection`, shared by Add and Edit). Logs one event with
/// a custom name (the default `-dp_uitest` seed's beer has `customName == nil`,
/// so it contributes no suggestion), then proves typing a single-character
/// prefix on a fresh Add-Drink form surfaces that name as a tappable suggestion
/// that fills the field.
@MainActor
final class CustomNameAutocompleteUITests: XCTestCase {
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

    func test_typingPrefix_showsSuggestion_tapFillsField() throws {
        launchApp()

        // Log one Wine event with a custom name — the history entry the
        // suggestion list will later surface.
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

        // Open a fresh Add-Drink form and type only the first character.
        openAddDrinkSheet()
        let wineTileAgain = app.buttons["Wine"]
        XCTAssertTrue(wineTileAgain.waitForExistence(timeout: 10),
                      "Wine tile should be visible in the Add Drink grid")
        wineTileAgain.tap()
        XCTAssertTrue(app.navigationBars["Wine"].waitForExistence(timeout: 5),
                      "Wine detail screen navigation bar should appear")

        let field = app.textFields["Custom Name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5),
                      "Custom Name text field should be present in the detail screen")
        field.tap()
        field.typeText("B")

        let suggestionButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", customName)
        ).firstMatch
        XCTAssertTrue(suggestionButton.waitForExistence(timeout: 5),
                      "A suggestion for '\(customName)' should appear after typing 'B'")
        suggestionButton.tap()

        XCTAssertEqual(field.value as? String, customName,
                       "Tapping the suggestion should fill the field with the exact suggested name")
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
}
