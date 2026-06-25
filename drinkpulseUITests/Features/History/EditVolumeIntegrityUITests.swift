import XCTest

/// Pins the data-corruption regression at the UI layer (plan-0030).
///
/// A 500 ml beer opened in `.usCustomary` must NOT be snapped to the nearest
/// US grid row (~473 ml / 16.0 fl oz) on a save-without-interaction.
///
/// Accessibility structure note: History list cells have `.label == ""`.
/// The EventRow is rendered as a `.buttonStyle(.plain)` Button inside the
/// cell; its combined accessibilityLabel is on the Button, not the cell
/// container.  We query `app.buttons.matching(…)` accordingly.
@MainActor
final class EditVolumeIntegrityUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Builds and launches the app. Kept off the nonisolated `setUpWithError`
    /// override so the MainActor-isolated XCUI calls run on the MainActor.
    private func launchApp() {
        app = XCUIApplication()
        // Onboarding skipped; in-memory store seeded with a 500 ml beer
        // and a profile set to .usCustomary.
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "usCustomary",
        ]
        app.launch()
    }

    /// Opens the seeded beer event in EditEventView, taps Save without
    /// touching the volume picker, and asserts the event row still shows
    /// ~16.9 fl oz (the 500 ml original converted to US fl oz), NOT
    /// snapped to the nearest US grid row (16.0 fl oz / 473 ml).
    func test_editUntouched_preservesOriginal500mlAsFlOz() throws {
        launchApp()
        openHistoryTab()

        let beerButton = eventButton(containing: "16.9")
        XCTAssertTrue(beerButton.waitForExistence(timeout: 10),
                      "Seeded beer row should show '16.9 fl oz' (500 ml in US mode)")

        let labelBefore = beerButton.label

        // Open edit sheet.
        beerButton.tap()

        // Confirm EditEventView opened via its navigation title.
        let editNavBar = app.navigationBars["Edit Drink"]
        XCTAssertTrue(editNavBar.waitForExistence(timeout: 5),
                      "Edit Drink sheet should open after tapping the row")

        // Tap Save immediately — no picker interaction.
        let saveButton = editNavBar.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3),
                      "Save button should be in the Edit Drink nav bar")
        saveButton.tap()

        // Sheet dismisses; History list returns.
        let histList = app.collectionViews.firstMatch
        XCTAssertTrue(histList.waitForExistence(timeout: 5),
                      "History list should return after save")

        // The row must still show 16.9 fl oz — not 16.0 fl oz (473 ml snap).
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
