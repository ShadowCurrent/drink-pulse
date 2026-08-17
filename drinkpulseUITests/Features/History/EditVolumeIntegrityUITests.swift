import XCTest

@MainActor
final class EditVolumeIntegrityUITests: XCTestCase {
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

    func test_editUntouched_preservesOriginal500mlAsFlOz() throws {
        launchApp()
        openHistoryTab()

        let beerButton = eventButton(containing: "16.9")
        XCTAssertTrue(beerButton.waitForExistence(timeout: 10),
                      "Seeded beer row should show '16.9 fl oz' (500 ml in US mode)")

        let labelBefore = beerButton.label

        beerButton.tap()

        let editNavBar = app.navigationBars["Edit Drink"]
        XCTAssertTrue(editNavBar.waitForExistence(timeout: 5),
                      "Edit Drink sheet should open after tapping the row")

        let saveButton = editNavBar.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3),
                      "Save button should be in the Edit Drink nav bar")
        saveButton.tap()

        XCTAssertFalse(editNavBar.waitForExistence(timeout: 5),
                      "Edit Drink sheet should be dismissed after save")

        let beerButtonAfter = eventButton(containing: "16.9")
        XCTAssertTrue(beerButtonAfter.waitForExistence(timeout: 5),
                      "After untouched save the row should still show ~16.9 fl oz (500 ml), "
                      + "but it was not found")

        let labelAfter = beerButtonAfter.label
        XCTAssertFalse(labelAfter.contains("16.0"),
                       "Row must NOT show 16.0 fl oz (473 ml snap) after save, "
                       + "got '\(labelAfter)'")
        XCTAssertEqual(labelBefore, labelAfter,
                       "Row label must be unchanged by a no-op save")
    }

    // MARK: - Helpers

    private func openHistoryTab() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10),
                      "History tab should be accessible after launch")
        tab.tap()
    }

    private func eventButton(containing substring: String) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", substring)
        ).firstMatch
    }
}
