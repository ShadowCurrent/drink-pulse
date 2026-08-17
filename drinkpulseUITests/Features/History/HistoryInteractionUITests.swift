import XCTest

@MainActor
final class HistoryInteractionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func launchApp(dataset: String? = nil) {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        if let dataset {
            app.launchArguments += ["-dp_uitest_dataset", dataset]
        }
        app.launch()
    }

    // MARK: - Segmented control: List ↔ Calendar

    func test_segmentSwitch_togglesListAndCalendar() throws {
        launchApp()
        openHistoryTab()

        let beerRow = eventButton(containing: "500 ml")
        XCTAssertTrue(beerRow.waitForExistence(timeout: 10),
                      "List segment should show the seeded 500 ml beer row")
        XCTAssertTrue(app.staticTexts["Today"].exists,
                      "List segment should show a 'Today' section header")

        tapSegment("Calendar")

        let todayCell = calendarDayCell(forTodayNumber: currentDayNumber())
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5),
                      "Calendar segment should render today's day cell (number \(currentDayNumber()))")
        XCTAssertFalse(app.staticTexts["Today"].exists,
                       "Calendar segment should not show the List's 'Today' section header")

        tapSegment("List")
        XCTAssertTrue(eventButton(containing: "500 ml").waitForExistence(timeout: 5),
                      "Returning to List should show the beer row again")
    }

    // MARK: - Calendar day → day detail

    func test_tapCalendarDay_revealsDayDetail() throws {
        launchApp()
        openHistoryTab()
        tapSegment("Calendar")

        let todayCell = calendarDayCell(forTodayNumber: currentDayNumber())
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5),
                      "Today's calendar day cell should exist")
        todayCell.tap()

        let detailRow = eventButton(containing: "500 ml")
        XCTAssertTrue(detailRow.waitForExistence(timeout: 5),
                      "Tapping today's day cell should reveal a day-detail row for the 500 ml beer")

        detailRow.tap()
        XCTAssertTrue(app.navigationBars["Edit Drink"].waitForExistence(timeout: 5),
                      "Tapping a day-detail row should open the Edit Drink sheet")
    }

    func test_calendar_selectsTodayInitially_andNeverDeselects() throws {
        launchApp()
        openHistoryTab()
        tapSegment("Calendar")

        let detailRow = eventButton(containing: "500 ml")
        XCTAssertTrue(detailRow.waitForExistence(timeout: 5),
                      "Calendar should pre-select today and show its day-detail row on entry")

        let todayCell = calendarDayCell(forTodayNumber: currentDayNumber())
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5), "Today's cell should exist")
        todayCell.tap()
        XCTAssertTrue(eventButton(containing: "500 ml").waitForExistence(timeout: 5),
                      "Tapping the selected day must not deselect it; detail stays visible")
    }

    // MARK: - Context-menu Duplicate

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

        XCTAssertTrue(waitForBeerRowCount(2, timeout: 5),
                      "Duplicate should add a second 500 ml beer row (count became \(beerRowCount()))")
    }

    // MARK: - Context-menu Delete

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

        let confirm = app.buttons["confirmContextDeleteButton"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5),
                      "Context-menu Delete should open a confirmation, not delete immediately")
        confirm.tap()

        XCTAssertTrue(waitForBeerRowCount(0, timeout: 5),
                      "Context-menu Delete, once confirmed, should remove the only beer row")
    }

    // MARK: - Edit custom name & notes persist

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

        let nameField = app.textFields["Custom Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5),
                      "Custom Name field should be present")
        nameField.tap()
        nameField.typeText("Tyskie IPA")

        let notesField = app.textViews.firstMatch.exists
            ? app.textViews.firstMatch
            : app.textFields["e.g. Friday pub night with Anna"]
        XCTAssertTrue(notesField.waitForExistence(timeout: 5),
                      "Notes field should be present")
        notesField.tap()
        notesField.typeText("Quiet evening")

        editNav.buttons["Save"].tap()

        let renamedRow = eventButton(containing: "Tyskie IPA")
        XCTAssertTrue(renamedRow.waitForExistence(timeout: 5),
                      "After save the row should show the custom name 'Tyskie IPA'")
        XCTAssertTrue(renamedRow.label.contains("500 ml"),
                      "Editing name/notes must NOT rewrite the stored volume — "
                      + "expected '500 ml' to remain, got '\(renamedRow.label)'")

        renamedRow.tap()
        XCTAssertTrue(app.navigationBars["Edit Drink"].waitForExistence(timeout: 5),
                      "Re-opening the renamed row should reopen Edit Drink")

        let reopenedName = app.textFields["Custom Name"]
        XCTAssertTrue(reopenedName.waitForExistence(timeout: 5),
                      "Custom Name field should be present on re-open")
        XCTAssertEqual(reopenedName.value as? String, "Tyskie IPA",
                       "Saved custom name should persist and pre-fill on re-open")

        XCTAssertTrue(anyFieldValueContains("Quiet evening"),
                      "Saved note 'Quiet evening' should persist and reappear on re-open")
    }

    // MARK: - Edit category change persists

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

        let typeRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Beer")
        ).firstMatch
        XCTAssertTrue(typeRow.waitForExistence(timeout: 5),
                      "The Type row should show the current 'Beer' category")
        typeRow.tap()

        XCTAssertTrue(app.navigationBars["Change Type"].waitForExistence(timeout: 5),
                      "Tapping Type should push the Change Type grid")

        let wineTile = app.buttons["Wine"]
        XCTAssertTrue(wineTile.waitForExistence(timeout: 5),
                      "Change Type grid should offer a 'Wine' tile")
        wineTile.tap()

        XCTAssertTrue(editNav.waitForExistence(timeout: 5),
                      "Selecting Wine should pop back to the Edit Drink form")
        editNav.buttons["Save"].tap()

        let wineRow = eventButton(containing: "150 ml")
        XCTAssertTrue(wineRow.waitForExistence(timeout: 5),
                      "After changing to Wine the row should show the 150 ml wine default")
        XCTAssertFalse(eventButton(containing: "500 ml").waitForExistence(timeout: 2),
                       "The old 500 ml beer subtitle should be gone after the category change")
    }
}
