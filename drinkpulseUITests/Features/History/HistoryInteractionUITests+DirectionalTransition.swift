import XCTest

@MainActor
extension HistoryInteractionUITests {

    // MARK: - Segmented control: List ↔ Calendar (directional transition)

    func test_segmentSwitch_alternatingDirection_endsInCorrectState() throws {
        launchApp()
        openHistoryTab()

        let sequence = ["Calendar", "List", "Calendar", "List", "Calendar", "List"]
        for label in sequence {
            tapSegment(label)
            if label == "Calendar" {
                let todayCell = calendarDayCell(forTodayNumber: currentDayNumber())
                XCTAssertTrue(todayCell.waitForExistence(timeout: 5),
                              "Calendar segment should render today's day cell after tap to '\(label)'")
            } else {
                XCTAssertTrue(eventButton(containing: "500 ml").waitForExistence(timeout: 5),
                              "List segment should show the seeded beer row after tap to '\(label)'")
                XCTAssertTrue(app.staticTexts["Today"].exists,
                              "List segment should show the 'Today' section header after tap to '\(label)'")
            }
        }
    }

    func test_segmentSwitch_rapidRepeatedTaps_endsInCorrectState() throws {
        launchApp()
        openHistoryTab()

        for label in ["Calendar", "List", "Calendar", "List"] {
            let segmentButton = app.segmentedControls.buttons[label]
            XCTAssertTrue(segmentButton.waitForExistence(timeout: 5),
                          "History segment '\(label)' should exist")
            segmentButton.tap()
        }

        XCTAssertTrue(eventButton(containing: "500 ml").waitForExistence(timeout: 5),
                      "After a rapid tap burst ending on List, the seeded beer row should be visible")
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 5),
                      "After a rapid tap burst ending on List, the 'Today' section header should be visible")
    }

    func test_segmentSwitch_withEmptyState_transitionsCorrectly() throws {
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
                      "Delete, once confirmed, should remove the only beer row")
        XCTAssertTrue(app.staticTexts["No drinks logged"].waitForExistence(timeout: 5),
                      "List's empty state should appear after deleting the only event")

        tapSegment("Calendar")
        let todayCell = calendarDayCell(forTodayNumber: currentDayNumber())
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5),
                      "Calendar should render today's day cell correctly with zero events")

        tapSegment("List")
        XCTAssertTrue(app.staticTexts["No drinks logged"].waitForExistence(timeout: 5),
                      "The empty state should survive the round trip through the same transition container")
    }

    func test_segmentSwitch_withManyEvents_endsInCorrectState() throws {
        launchApp(dataset: "multiday")
        openHistoryTab()

        XCTAssertTrue(eventButton(containing: "500 ml").waitForExistence(timeout: 10),
                      "List should show today's seeded 500 ml beer row from the multiday fixture")

        tapSegment("Calendar")
        let todayCell = calendarDayCellForToday()
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5),
                      "Calendar should render today's day cell with the larger multiday fixture")

        tapSegment("List")
        XCTAssertTrue(eventButton(containing: "500 ml").waitForExistence(timeout: 5),
                      "Returning to List should show today's beer row again")
    }
}
