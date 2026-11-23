import XCTest

@MainActor
final class EditDeleteConfirmationUITests: XCTestCase {
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

    private func openHistoryTab() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10),
                      "History tab should be accessible after launch")
        tab.tap()
    }

    private func eventButton(containing substring: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
    }

    private func beerRowCount() -> Int {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "500 ml")).count
    }

    private func waitForBeerRowCount(_ expected: Int, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if beerRowCount() == expected { return true }
            usleep(150_000)
        }
        return beerRowCount() == expected
    }

    private func openEditScreen() -> XCUIElement {
        openHistoryTab()
        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "Seeded beer row should be present before editing")
        row.tap()
        let editNav = app.navigationBars["Edit Drink"]
        XCTAssertTrue(editNav.waitForExistence(timeout: 5),
                      "Tapping the row should push the Edit Drink screen")
        return editNav
    }

    /// Delete Drink sits at the bottom of the form. The drag starts low on the screen: a swipe
    /// from the centre lands on the serving wheels.
    private func tapDeleteDrink() {
        let delete = app.buttons["editDrink.delete"]
        let window = app.windows.firstMatch.frame
        for _ in 0..<6 where !(delete.exists
            && delete.frame.minY > window.minY + 120 && delete.frame.maxY < window.maxY - 100) {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
            start.press(forDuration: 0.05, thenDragTo: app.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)))
            usleep(800_000) // let the scroll settle before reading frames
        }
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "Edit Drink should offer Delete Drink")
        delete.tap()
    }

    // MARK: - Confirm path

    func test_editDelete_confirm_removesEventAndPops() throws {
        launchApp()
        _ = openEditScreen()

        tapDeleteDrink()
        let confirm = app.buttons["confirmDeleteButton"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5),
                      "Delete Drink should open the confirmation dialog")
        confirm.tap()

        XCTAssertTrue(app.navigationBars["Edit Drink"].waitForNonExistence(timeout: 5),
                      "Confirming delete should pop back to History")
        XCTAssertTrue(waitForBeerRowCount(0, timeout: 5),
                      "Confirming delete should remove the only beer row")
    }

    // MARK: - Dialog copy

    func test_editDelete_dialog_saysWhatHappens() throws {
        launchApp()
        _ = openEditScreen()

        tapDeleteDrink()
        XCTAssertTrue(app.staticTexts["Delete this drink?"].waitForExistence(timeout: 5),
                      "The dialog title asks for confirmation")
        XCTAssertTrue(app.staticTexts["This drink will be removed from your history."].exists,
                      "The dialog message says what happens (VOICE.md)")
    }

    // MARK: - Dismiss path

    func test_editDelete_dismissDialog_keepsEvent() throws {
        launchApp()
        let editNav = openEditScreen()

        tapDeleteDrink()
        XCTAssertTrue(app.buttons["confirmDeleteButton"].firstMatch.waitForExistence(timeout: 5),
                      "Delete Drink should open the confirmation dialog")
        // The dialog is a popover anchored to Delete Drink; tap the form well above it. No
        // system label is matched (simulator locale).
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
        XCTAssertTrue(app.buttons["confirmDeleteButton"].firstMatch.waitForNonExistence(timeout: 3),
                      "Tapping outside should dismiss the dialog without deleting")

        editNav.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(editNav.waitForNonExistence(timeout: 5), "Back should pop to History")
        XCTAssertTrue(waitForBeerRowCount(1, timeout: 5),
                      "Dismissing the dialog must NOT delete the event")
    }
}
