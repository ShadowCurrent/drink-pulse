import XCTest

@MainActor
final class HealthWriteHooksUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The Health sample-count probe is a one point non-text element, so it is read through a
    /// type-independent query: identifier match, label carries the count.
    private var healthSampleProbe: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "dp_health_sample_count").firstMatch
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
            "-dp_health_write_enabled", "YES",
        ]
        app.launch()
    }

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

    func test_healthEnabled_logDrink_writesHealthSample() throws {
        launchApp()

        let probe = healthSampleProbe
        XCTAssertTrue(probe.waitForExistence(timeout: 10),
                      "Health sample-count probe should be present under -dp_uitest")
        XCTAssertEqual(probe.label, "0",
                       "No Health sample should exist before logging a drink")

        openAddDrinkSheet()
        let wineTile = app.buttons["Wine"]
        XCTAssertTrue(wineTile.waitForExistence(timeout: 10), "Wine tile should be visible")
        wineTile.tap()
        XCTAssertTrue(app.navigationBars["Wine"].waitForExistence(timeout: 5),
                      "Wine detail screen should appear")
        save(on: "Wine")

        XCTAssertTrue(waitForProbeLabel("1", timeout: 10),
                      "Logging a drink with Health enabled must write exactly one Health sample")
    }

    func test_healthEnabled_deleteDrink_stillRemovesEvent() throws {
        launchApp()
        openHistoryTab()

        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "Seeded beer row should be present before deleting")
        row.press(forDuration: 1.2)

        let delete = app.buttons["Delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5),
                      "Context menu should offer a 'Delete' action")
        delete.tap()

        let confirm = app.buttons["confirmContextDeleteButton"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5),
                      "Context-menu Delete should open a confirmation, not delete immediately")
        confirm.tap()

        XCTAssertTrue(waitForRowCount(containing: "500 ml", toReach: 0, timeout: 5),
                      "With Health enabled, deleting once confirmed should still remove the only beer row")
    }

    /// Integration evidence for finding F2 (10-DECISION-F2.md): log, edit, then delete leaves zero
    /// Health samples. The UI-test store completes instantly, so the stale-UUID race itself is not
    /// reproducible here; it is pinned by `HealthServiceConcurrencyTests`. This test proves the
    /// user flow wires edit and delete through the Health hooks end to end.
    func test_healthEnabled_logEditDelete_leavesNoHealthSample() throws {
        launchApp()

        let probe = healthSampleProbe
        XCTAssertTrue(probe.waitForExistence(timeout: 10),
                      "Health sample-count probe should be present under -dp_uitest")
        XCTAssertEqual(probe.label, "0", "No Health sample should exist before logging a drink")

        openAddDrinkSheet()
        let wineTile = app.buttons["Wine"]
        XCTAssertTrue(wineTile.waitForExistence(timeout: 10), "Wine tile should be visible")
        wineTile.tap()
        XCTAssertTrue(app.navigationBars["Wine"].waitForExistence(timeout: 5),
                      "Wine detail screen should appear")
        let baseName = "Health Edit Wine"
        typeCustomName(baseName)
        save(on: "Wine")
        XCTAssertTrue(waitForProbeLabel("1", timeout: 10),
                      "Logging a drink with Health enabled must write exactly one Health sample")

        openHistoryTab()
        let loggedRow = eventButton(containing: baseName)
        XCTAssertTrue(loggedRow.waitForExistence(timeout: 10), "Logged wine should appear in History")
        loggedRow.tap()
        let editNav = app.navigationBars["Edit Drink"]
        XCTAssertTrue(editNav.waitForExistence(timeout: 5), "Tapping the row should open Edit Drink")
        let nameField = app.textFields["Custom Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Custom Name field should be present")
        nameField.tap()
        nameField.typeText(" Edited")
        editNav.buttons["Save"].tap()
        XCTAssertTrue(editNav.waitForNonExistence(timeout: 5), "Saving should dismiss Edit Drink")
        XCTAssertTrue(eventButton(containing: "Edited").waitForExistence(timeout: 10),
                      "The edited name should show in History")
        XCTAssertTrue(waitForProbeLabel("1", timeout: 10),
                      "Editing a drink must replace its Health sample, never add a second one")

        eventButton(containing: baseName).tap()
        XCTAssertTrue(editNav.waitForExistence(timeout: 5), "Tapping the row should reopen Edit Drink")
        editNav.buttons["Delete"].tap()
        let confirm = app.buttons["confirmDeleteButton"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Delete should open a confirmation")
        confirm.tap()

        XCTAssertTrue(waitForRowCount(containing: baseName, toReach: 0, timeout: 5),
                      "Confirmed delete should remove the edited event from History")
        XCTAssertTrue(waitForProbeLabel("0", timeout: 10),
                      "Deleting an edited drink must leave zero Health samples")
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

    private func waitForProbeLabel(_ expected: String, timeout: TimeInterval) -> Bool {
        let probe = healthSampleProbe
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if probe.exists, probe.label == expected { return true }
            usleep(150_000)
        }
        return probe.exists && probe.label == expected
    }
}
