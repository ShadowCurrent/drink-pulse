import XCTest

@MainActor
final class ContextMenuDeleteConfirmationUITests: XCTestCase {
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

    private func confirmDeleteButton() -> XCUIElement {
        app.buttons["confirmContextDeleteButton"].firstMatch
    }

    private func waitForBeerRowCount(_ expected: Int, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if beerRowCount() == expected { return true }
            usleep(150_000)
        }
        return beerRowCount() == expected
    }

    private func openContextMenuOnSeededRow() {
        openHistoryTab()
        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "Seeded beer row should be present before long-pressing it")
        row.press(forDuration: 1.2)
    }

    // MARK: - Confirm path

    func test_contextMenuDelete_confirm_removesRow() throws {
        launchApp()
        openContextMenuOnSeededRow()

        let menuDelete = app.buttons["Delete"]
        XCTAssertTrue(menuDelete.waitForExistence(timeout: 5),
                      "Context menu should offer Delete")
        menuDelete.tap()

        let confirm = confirmDeleteButton()
        XCTAssertTrue(confirm.waitForExistence(timeout: 5),
                      "Context-menu Delete must open a confirmation, not delete immediately")
        confirm.tap()

        XCTAssertTrue(waitForBeerRowCount(0, timeout: 5),
                      "Confirming should remove the only beer row")
    }

    // MARK: - Cancel path

    func test_contextMenuDelete_cancel_keepsRow() throws {
        launchApp()
        openContextMenuOnSeededRow()

        let menuDelete = app.buttons["Delete"]
        XCTAssertTrue(menuDelete.waitForExistence(timeout: 5),
                      "Context menu should offer Delete")
        menuDelete.tap()

        let confirm = confirmDeleteButton()
        XCTAssertTrue(confirm.waitForExistence(timeout: 5),
                      "Context-menu Delete must open a confirmation, not delete immediately")

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()

        XCTAssertFalse(confirmDeleteButton().waitForExistence(timeout: 3),
                       "Dismissing should close the confirmation without deleting")
        XCTAssertTrue(waitForBeerRowCount(1, timeout: 5),
                      "Dismissing the confirmation must NOT delete the drink")
        XCTAssertTrue(eventButton(containing: "500 ml").isHittable,
                      "The kept row must still be interactive after dismissing")
    }

    // MARK: - Duplicate is not gated

    func test_contextMenuDuplicate_isNotGatedByConfirmation() throws {
        launchApp()
        openContextMenuOnSeededRow()

        let duplicate = app.buttons["Duplicate"]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5),
                      "Context menu should offer Duplicate")
        duplicate.tap()

        XCTAssertFalse(confirmDeleteButton().waitForExistence(timeout: 3),
                       "Duplicate is non-destructive and must not be gated by a confirmation")
        XCTAssertTrue(waitForBeerRowCount(2, timeout: 5),
                      "Duplicate should immediately produce a second 500 ml beer row")
    }
}
