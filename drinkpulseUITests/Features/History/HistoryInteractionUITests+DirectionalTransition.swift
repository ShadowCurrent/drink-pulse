import XCTest

/// Directional-transition UI coverage for the History segmented control
/// (plan-0006-01, HIST-01/HIST-03, D-05). Split into its own file to keep
/// `HistoryInteractionUITests.swift` from growing further — that file's own
/// doc comment already flags it as over the project's 300-line ceiling.
///
/// These tests prove correct END-STATE content after alternating, rapid,
/// empty-state, and larger-dataset segment switches. XCUITest cannot assert
/// animation direction or mid-transition frame content (see the `<human-check>`
/// items in `06-01-PLAN.md` Task 2 for the genuinely manual-only checks).
@MainActor
extension HistoryInteractionUITests {

    // MARK: - Segmented control: List ↔ Calendar (directional transition)

    /// A longer alternating burst (six taps, three full round trips) always
    /// lands on the segment matching the LAST tap with fully-formed content.
    /// Proves `edge(forEntering:)`'s statelessness holds through a real
    /// alternating sequence — no stuck/desynced content between switches.
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

    /// A rapid, back-to-back tap sequence (no `waitForExistence` between
    /// intermediate taps) still ends on the correct final state. Some taps may
    /// land while the prior ~0.4s spring transition is still animating.
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

    /// Switching into and out of the empty state (reached via context-menu
    /// Delete) uses the identical `.transition` container as populated
    /// content — no special-cased instant swap (D-05).
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

        XCTAssertTrue(waitForBeerRowCount(0, timeout: 5),
                      "Delete should remove the only beer row")
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

    /// A larger, deterministic 9-event/14-day fixture (`-dp_uitest_dataset
    /// multiday`) still switches to correct end-state content, not just the
    /// 1-event default seed.
    func test_segmentSwitch_withManyEvents_endsInCorrectState() throws {
        launchApp(dataset: "multiday")
        openHistoryTab()

        XCTAssertTrue(eventButton(containing: "500 ml").waitForExistence(timeout: 10),
                      "List should show today's seeded 500 ml beer row from the multiday fixture")

        tapSegment("Calendar")
        let todayCell = calendarDayCell(forTodayNumber: currentDayNumber())
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5),
                      "Calendar should render today's day cell with the larger multiday fixture")

        tapSegment("List")
        XCTAssertTrue(eventButton(containing: "500 ml").waitForExistence(timeout: 5),
                      "Returning to List should show today's beer row again")
    }
}
