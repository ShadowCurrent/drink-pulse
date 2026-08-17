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

    private func openEditSheet() -> XCUIElement {
        openHistoryTab()
        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "Seeded beer row should be present before editing")
        row.tap()
        let editNav = app.navigationBars["Edit Drink"]
        XCTAssertTrue(editNav.waitForExistence(timeout: 5),
                      "Tapping the row should open the Edit Drink sheet")
        return editNav
    }

    // MARK: - Confirm path

    func test_editDelete_confirm_removesEventAndDismisses() throws {
        launchApp()
        let editNav = openEditSheet()

        editNav.buttons["Delete"].tap()

        XCTAssertTrue(app.staticTexts["Delete this drink?"].waitForExistence(timeout: 5),
                      "Tapping the trash button should open the delete-confirmation popover")

        let confirm = app.buttons["confirmDeleteButton"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5),
                      "Popover should expose the confirm Delete button")
        confirm.tap()

        XCTAssertFalse(app.navigationBars["Edit Drink"].waitForExistence(timeout: 5),
                       "Confirming delete should dismiss the Edit Drink sheet")
        XCTAssertTrue(waitForBeerRowCount(0, timeout: 5),
                      "Confirming delete should remove the only beer row")
    }

    // MARK: - Cancel path

    func test_editDelete_dismissPopover_keepsEvent() throws {
        launchApp()
        let editNav = openEditSheet()

        editNav.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Delete this drink?"].waitForExistence(timeout: 5),
                      "Tapping the trash button should open the delete-confirmation popover")

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()
        XCTAssertFalse(app.staticTexts["Delete this drink?"].waitForExistence(timeout: 3),
                       "Tapping outside should dismiss the popover without deleting")

        editNav.buttons["Cancel"].tap()
        XCTAssertTrue(waitForBeerRowCount(1, timeout: 5),
                      "Dismissing the popover must NOT delete the event")
    }
}
