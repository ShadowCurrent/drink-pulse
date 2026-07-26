import XCTest

/// Regression coverage for a data-loss bug: editing a freshly-duplicated
/// `ConsumptionEvent` (via the History "Duplicate" context-menu action) could
/// silently lose all unsaved edits a few seconds into the edit session.
///
/// Root cause: `EventContextMenu`'s Duplicate action `context.insert()`-ed the
/// copy without saving. A freshly-inserted, not-yet-saved SwiftData object
/// carries a TEMPORARY `PersistentIdentifier` that only becomes permanent once
/// the context saves. `HistoryView`'s `.sheet(item: $editingEvent)` is keyed by
/// that identifier; when SwiftData's own autosave fired while the user was
/// still editing the duplicate (empirically, several seconds after insert),
/// the identifier flipped, and SwiftUI read that as "a different item is now
/// presented" — tearing down and reconstructing `EditEventView` from the model,
/// discarding every unsaved field, even though the sheet's own chrome (nav bar
/// title) never visibly changed. Fix: `EventContextMenu` now calls
/// `context.save()` immediately after inserting the duplicate, so its identity
/// is already permanent before the row is ever tappable.
///
/// This test can't force SwiftData's autosave timing directly, so it pins the
/// regression the same way it was diagnosed: duplicate, open Edit on the
/// fresh copy, enter data, and wait past the empirically-observed autosave
/// window before asserting the data is still there.
@MainActor
final class DuplicateEditPersistenceUITests: XCTestCase {
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

    /// Duplicate the seeded event, open the fresh duplicate's Edit sheet, enter
    /// a Custom Name, wait 10s (past the observed autosave-triggered identity
    /// flip), then confirm the sheet is still showing the entered value.
    func test_editFreshDuplicate_survivesPastAutosaveWindow() throws {
        launchApp()

        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should be accessible")
        tab.tap()

        func eventButton(containing substring: String) -> XCUIElement {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
        }

        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Seeded beer row should be present")
        row.press(forDuration: 1.2)

        let duplicate = app.buttons["Duplicate"]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5), "Context menu should offer Duplicate")
        duplicate.tap()

        // Wait for the duplicate row to appear (2 matching rows now).
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "500 ml")).count == 2 { break }
            usleep(150_000)
        }
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "500 ml")).count, 2,
                       "Duplicate should produce a second 500 ml beer row")

        // The newest (freshly duplicated) row sorts to the top of "Today".
        let topRow = eventButton(containing: "500 ml")
        topRow.tap()

        let editNav = app.navigationBars["Edit Drink"]
        XCTAssertTrue(editNav.waitForExistence(timeout: 5), "Edit Drink sheet should open on the duplicate")

        let nameField = app.textFields["Custom Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Custom Name field should be present")
        nameField.tap()
        nameField.typeText("Regression Marker\n")

        // Wait past the empirically-observed ~7-8s window in which the bug
        // reset the field before the fix. 10s gives headroom.
        Thread.sleep(forTimeInterval: 10)

        XCTAssertTrue(app.navigationBars["Edit Drink"].exists,
                      "Edit Drink sheet must still be open after the wait")
        XCTAssertEqual(app.textFields["Custom Name"].value as? String, "Regression Marker",
                       "Custom Name entered while editing a freshly-duplicated event must not be "
                       + "silently reset once SwiftData's autosave has had time to run")
    }
}
