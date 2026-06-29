import XCTest

/// UI coverage for the Apple Health write hooks (plan-0036, W5).
///
/// With Health write-back ENABLED, the Add / Edit / Delete sites fire a
/// fire-and-forget Health op (gated on `dp_health_write_enabled`). These hooks
/// must NEVER block or break the in-app flow. This test proves exactly that: with
/// Health on, logging a drink still saves and appears in History, and deleting it
/// still removes it.
///
/// Setup notes:
/// - `-dp_uitest` routes `HealthService` to the non-prompting `UITestHealthStore`
///   stub (auto-grants, in-memory) — no real Health permission sheet, no device
///   Health store touched.
/// - `-dp_health_write_enabled YES` lands in the NSArgumentDomain, which outranks
///   the app-domain key that `UITestSeed.resetTransientDefaults()` clears, so the
///   write-back gate reads ON for this run (mirrors the `-dp_onboarding_done`
///   override pattern). The actual HK sample is unit-covered in W3; XCUITest can
///   only assert the in-app flow integrity, which is the point here.
///
/// Locators key off app-rendered ENGLISH text (English-only app), never a
/// system-process control, so the Polish simulator locale is irrelevant.
@MainActor
final class HealthWriteHooksUITests: XCTestCase {
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
            // Enable Health write-back so the Add/Delete hooks actually fire.
            "-dp_health_write_enabled", "YES",
        ]
        app.launch()
    }

    /// With Health enabled, logging a drink still succeeds and the new event shows
    /// in History — the write hook must not block or break the save flow.
    func test_healthEnabled_logDrink_stillAppearsInHistory() throws {
        launchApp()
        openAddDrinkSheet()

        let wineTile = app.buttons["Wine"]
        XCTAssertTrue(wineTile.waitForExistence(timeout: 10),
                      "Wine tile should be visible in the Add Drink grid")
        wineTile.tap()
        XCTAssertTrue(app.navigationBars["Wine"].waitForExistence(timeout: 5),
                      "Wine detail screen navigation bar should appear")

        let customName = "Health Hook Wine"
        typeCustomName(customName)
        save(on: "Wine")

        openHistoryTab()
        let savedRow = eventButton(containing: customName)
        XCTAssertTrue(savedRow.waitForExistence(timeout: 10),
                      "With Health enabled, the newly-logged event should still appear in History")
    }

    /// With Health enabled, deleting a logged event still removes it — the remove
    /// hook captures ids and runs fire-and-forget, never blocking the delete.
    func test_healthEnabled_deleteDrink_stillRemovesEvent() throws {
        launchApp()
        openHistoryTab()

        // The deterministic seed inserts one 500 ml beer.
        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "Seeded beer row should be present before deleting")
        row.press(forDuration: 1.2)

        let delete = app.buttons["Delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5),
                      "Context menu should offer a 'Delete' action")
        delete.tap()

        XCTAssertTrue(waitForRowCount(containing: "500 ml", toReach: 0, timeout: 5),
                      "With Health enabled, deleting should still remove the only beer row")
    }

    // MARK: - Helpers

    private func openAddDrinkSheet() {
        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10),
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

    private func rowCount(containing substring: String) -> Int {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).count
    }

    private func waitForRowCount(containing substring: String, toReach expected: Int, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if rowCount(containing: substring) == expected { return true }
            usleep(150_000)
        }
        return rowCount(containing: substring) == expected
    }
}
