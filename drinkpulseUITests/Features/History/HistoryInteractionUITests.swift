import XCTest

/// UI coverage for the History feature's interactive surfaces (plan-0032, step 4).
///
/// Complements the existing History tests:
/// - `EditVolumeIntegrityUITests` — untouched edit preserves the stored volume.
/// - `HistoryUnitDisplayUITests` — unit switch re-renders the subtitle.
///
/// This file covers what those don't: the List ↔ Calendar segmented control,
/// tapping a calendar day → day detail, context-menu Duplicate / Delete and
/// swipe-to-delete, and that editing custom name, notes, and category persist.
///
/// Accessibility structure note: every `EventRow` is a `.buttonStyle(.plain)`
/// Button (in the List or the calendar day detail) whose combined
/// accessibilityLabel carries the rendered name, volume, ABV and amount. We
/// query `app.buttons.matching(…)` against that label. No accessibility
/// identifiers exist in the app, so all matching is on app-rendered ENGLISH
/// text. The simulator system locale is Polish; calendar day cells expose a
/// locale-formatted label, so they are addressed by their day NUMBER (a stable
/// numeric string), never by a localized month/weekday name.
///
/// Seed: `-dp_uitest YES` inserts a single "Today" 500 ml 5% beer in an
/// in-memory store. In metric the row renders name "Bottle" / subtitle
/// "500 ml · 5.0% · <time>". That single event is sufficient for every flow
/// here (segment switch, today's calendar day, duplicate/delete, edit).
@MainActor
final class HistoryInteractionUITests: XCTestCase {
    /// Internal (not `private`) so the helper extension in
    /// `HistoryInteractionUITests+Helpers.swift` can reach it.
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Builds and launches the app onto the History tab's data. Kept off the
    /// nonisolated `setUpWithError` so MainActor-isolated XCUI calls run on the
    /// MainActor.
    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        app.launch()
    }

    // MARK: - Segmented control: List ↔ Calendar

    /// The History segmented control switches between the List view (event rows
    /// grouped under "Today") and the Calendar view (a month grid). Each segment
    /// shows content unique to it.
    func test_segmentSwitch_togglesListAndCalendar() throws {
        launchApp()
        openHistoryTab()

        // List is the default segment: the seeded beer row is present and the
        // "Today" section header is shown.
        let beerRow = eventButton(containing: "500 ml")
        XCTAssertTrue(beerRow.waitForExistence(timeout: 10),
                      "List segment should show the seeded 500 ml beer row")
        XCTAssertTrue(app.staticTexts["Today"].exists,
                      "List segment should show a 'Today' section header")

        // Switch to Calendar.
        tapSegment("Calendar")

        // The calendar grid renders this month's days. Today's numeric day cell
        // is a tappable button; the List's "Today" section header is gone.
        let todayCell = calendarDayCell(forTodayNumber: currentDayNumber())
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5),
                      "Calendar segment should render today's day cell (number \(currentDayNumber()))")
        XCTAssertFalse(app.staticTexts["Today"].exists,
                       "Calendar segment should not show the List's 'Today' section header")

        // Switch back to List.
        tapSegment("List")
        XCTAssertTrue(eventButton(containing: "500 ml").waitForExistence(timeout: 5),
                      "Returning to List should show the beer row again")
    }

    // MARK: - Calendar day → day detail

    /// Tapping today's calendar day cell reveals the day-detail panel below the
    /// grid, listing that day's events (the seeded beer) as tappable rows.
    func test_tapCalendarDay_revealsDayDetail() throws {
        launchApp()
        openHistoryTab()
        tapSegment("Calendar")

        let todayCell = calendarDayCell(forTodayNumber: currentDayNumber())
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5),
                      "Today's calendar day cell should exist")
        todayCell.tap()

        // The day-detail panel lists the seeded beer event for today.
        let detailRow = eventButton(containing: "500 ml")
        XCTAssertTrue(detailRow.waitForExistence(timeout: 5),
                      "Tapping today's day cell should reveal a day-detail row for the 500 ml beer")

        // Tapping that row opens the Edit Drink sheet (proves the detail row is
        // wired to the edit flow, not just decorative).
        detailRow.tap()
        XCTAssertTrue(app.navigationBars["Edit Drink"].waitForExistence(timeout: 5),
                      "Tapping a day-detail row should open the Edit Drink sheet")
    }

    // MARK: - Context-menu Duplicate

    /// Long-pressing a List row opens the context menu; tapping Duplicate inserts
    /// a copy, so the count of matching beer rows goes from 1 to 2.
    func test_contextMenuDuplicate_addsEvent() throws {
        launchApp()
        openHistoryTab()

        XCTAssertTrue(eventButton(containing: "500 ml").waitForExistence(timeout: 10),
                      "Seeded beer row should be present before duplicating")
        XCTAssertEqual(beerRowCount(), 1, "There should be exactly one beer row to start")

        let row = eventButton(containing: "500 ml")
        row.press(forDuration: 1.2)

        let duplicate = app.buttons["Duplicate"]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5),
                      "Context menu should offer a 'Duplicate' action")
        duplicate.tap()

        // A second identical beer row now exists.
        XCTAssertTrue(waitForBeerRowCount(2, timeout: 5),
                      "Duplicate should add a second 500 ml beer row (count became \(beerRowCount()))")
    }

    // MARK: - Context-menu Delete

    /// Long-pressing a List row → Delete removes that event, leaving an empty
    /// History (the empty-state title appears).
    func test_contextMenuDelete_removesEvent() throws {
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

        XCTAssertTrue(waitForBeerRowCount(0, timeout: 5),
                      "Context-menu Delete should remove the only beer row")
    }

    // MARK: - Swipe Delete

    /// Swiping a List row left reveals the destructive trash action; tapping it
    /// removes the event.
    func test_swipeDelete_removesEvent() throws {
        launchApp()
        openHistoryTab()

        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "Seeded beer row should be present before swiping")

        // The trailing swipe action is an Image(systemName: "trash") destructive
        // Button with no accessibility label, so it is not addressable by name.
        // With `allowsFullSwipe: true` a long, fast left drag across the row
        // triggers the destructive action outright — drive that with a coordinate
        // drag from the right edge to the far left.
        let start = row.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let end = row.coordinate(withNormalizedOffset: CGVector(dx: -2.0, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)

        XCTAssertTrue(waitForBeerRowCount(0, timeout: 5),
                      "Swipe Delete (full swipe) should remove the only beer row")
    }

    // MARK: - Edit custom name & notes persist

    /// Editing the custom name and notes in the Edit Drink sheet and saving
    /// persists both: the row title shows the custom name and the note glyph
    /// (note.text) appears. Critically, the volume subtitle must STAY "500 ml" —
    /// editing unrelated fields must never silently rewrite the stored volume
    /// (data-integrity guard, plan-0030).
    func test_editCustomNameAndNotes_persist() throws {
        launchApp()
        openHistoryTab()

        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "Seeded beer row should be present before editing")
        row.tap()

        let editNav = app.navigationBars["Edit Drink"]
        XCTAssertTrue(editNav.waitForExistence(timeout: 5),
                      "Edit Drink sheet should open")

        // Custom name field (accessibilityLabel "Custom Name").
        let nameField = app.textFields["Custom Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5),
                      "Custom Name field should be present")
        nameField.tap()
        nameField.typeText("Tyskie IPA")

        // Notes field surfaces by its placeholder text.
        let notesField = app.textViews.firstMatch.exists
            ? app.textViews.firstMatch
            : app.textFields["e.g. Friday pub night with Anna"]
        XCTAssertTrue(notesField.waitForExistence(timeout: 5),
                      "Notes field should be present")
        notesField.tap()
        notesField.typeText("Quiet evening")

        editNav.buttons["Save"].tap()

        // The row title now carries the custom name, and the volume is unchanged.
        let renamedRow = eventButton(containing: "Tyskie IPA")
        XCTAssertTrue(renamedRow.waitForExistence(timeout: 5),
                      "After save the row should show the custom name 'Tyskie IPA'")
        XCTAssertTrue(renamedRow.label.contains("500 ml"),
                      "Editing name/notes must NOT rewrite the stored volume — "
                      + "expected '500 ml' to remain, got '\(renamedRow.label)'")

        // Re-open to confirm BOTH the custom name and notes persisted to the
        // model. The fields are pre-filled with the saved text on open.
        renamedRow.tap()
        XCTAssertTrue(app.navigationBars["Edit Drink"].waitForExistence(timeout: 5),
                      "Re-opening the renamed row should reopen Edit Drink")

        // Custom name persisted: the Custom Name field's value is "Tyskie IPA".
        let reopenedName = app.textFields["Custom Name"]
        XCTAssertTrue(reopenedName.waitForExistence(timeout: 5),
                      "Custom Name field should be present on re-open")
        XCTAssertEqual(reopenedName.value as? String, "Tyskie IPA",
                       "Saved custom name should persist and pre-fill on re-open")

        // Notes persisted: some field/view in the sheet now carries the note
        // text as its value (the vertical-axis TextField surfaces content via
        // `.value`, not as static text).
        XCTAssertTrue(anyFieldValueContains("Quiet evening"),
                      "Saved note 'Quiet evening' should persist and reappear on re-open")
    }

    // MARK: - Edit category change persists

    /// Changing the drink type from Beer to Wine in the Edit sheet, then saving,
    /// persists the new category: the row icon/name reflect wine and the serving
    /// resets to the wine metric default (150 ml). The original "500 ml" beer
    /// subtitle must be gone — a category change is a deliberate edit that adopts
    /// the new category's default serving (this is intended; we assert the rewrite
    /// happened correctly and only because the category actually changed).
    func test_editCategoryChange_persists() throws {
        launchApp()
        openHistoryTab()

        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10),
                      "Seeded beer row should be present before changing category")
        row.tap()

        let editNav = app.navigationBars["Edit Drink"]
        XCTAssertTrue(editNav.waitForExistence(timeout: 5),
                      "Edit Drink sheet should open")

        // Tap the Type row to push the change-type grid.
        let typeRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Beer")
        ).firstMatch
        XCTAssertTrue(typeRow.waitForExistence(timeout: 5),
                      "The Type row should show the current 'Beer' category")
        typeRow.tap()

        XCTAssertTrue(app.navigationBars["Change Type"].waitForExistence(timeout: 5),
                      "Tapping Type should push the Change Type grid")

        // Pick Wine (tile accessibilityLabel == preset.name == "Wine").
        let wineTile = app.buttons["Wine"]
        XCTAssertTrue(wineTile.waitForExistence(timeout: 5),
                      "Change Type grid should offer a 'Wine' tile")
        wineTile.tap()

        // Back on the form, save the category change.
        XCTAssertTrue(editNav.waitForExistence(timeout: 5),
                      "Selecting Wine should pop back to the Edit Drink form")
        editNav.buttons["Save"].tap()

        // The row now reflects wine: serving reset to the wine metric default
        // (150 ml) and the old 500 ml beer subtitle is gone.
        let wineRow = eventButton(containing: "150 ml")
        XCTAssertTrue(wineRow.waitForExistence(timeout: 5),
                      "After changing to Wine the row should show the 150 ml wine default")
        XCTAssertFalse(eventButton(containing: "500 ml").waitForExistence(timeout: 2),
                       "The old 500 ml beer subtitle should be gone after the category change")
    }
}
