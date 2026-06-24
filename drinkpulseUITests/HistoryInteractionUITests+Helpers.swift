import XCTest

/// Element-addressing helpers for `HistoryInteractionUITests`. Split out to keep
/// the test file under the 300-line ceiling. All matching keys off app-rendered
/// ENGLISH text or stable numeric values (the simulator system locale is Polish,
/// so locale-formatted labels are never matched directly).
@MainActor
extension HistoryInteractionUITests {

    func openHistoryTab() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10),
                      "History tab should be accessible after launch")
        tab.tap()
    }

    /// First button whose combined accessibility label contains `substring`.
    func eventButton(containing substring: String) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", substring)
        ).firstMatch
    }

    /// Number of List rows whose label contains the beer subtitle "500 ml".
    func beerRowCount() -> Int {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "500 ml")).count
    }

    func waitForBeerRowCount(_ expected: Int, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if beerRowCount() == expected { return true }
            usleep(150_000)
        }
        return beerRowCount() == expected
    }

    /// Taps a value in the History segmented control by its English label.
    func tapSegment(_ label: String) {
        let segment = app.segmentedControls.buttons[label]
        XCTAssertTrue(segment.waitForExistence(timeout: 5),
                      "History segment '\(label)' should exist")
        segment.tap()
    }

    /// Today's day-of-month as a String (locale-independent numeric value).
    func currentDayNumber() -> String {
        String(Calendar.current.component(.day, from: .now))
    }

    /// Today's calendar day cell, addressed by its day number. The cell renders
    /// the number as its visible text; its accessibility label is locale-
    /// formatted, so we match the numeric day string that is stable regardless
    /// of system locale. The cell is a button (tappable, not future-disabled).
    func calendarDayCell(forTodayNumber number: String) -> XCUIElement {
        // The day cell exposes the numeric day plus a grams suffix in its label
        // (e.g. "<date>, 20 g"); match the trailing grams marker which only
        // today's seeded cell carries, falling back to the bare number.
        let withGrams = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", " g")
        ).firstMatch
        if withGrams.exists { return withGrams }
        return app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", number)
        ).firstMatch
    }

    /// True if any text field or text view in the current sheet exposes a
    /// `value` containing `substring`. The notes editor is a vertical-axis
    /// `TextField`, whose pre-filled content surfaces via `.value` rather than
    /// as a separate static text element.
    func anyFieldValueContains(_ substring: String) -> Bool {
        let deadline = Date().addingTimeInterval(4)
        repeat {
            for query in [app.textViews, app.textFields] {
                for i in 0 ..< query.count {
                    if let value = query.element(boundBy: i).value as? String,
                       value.contains(substring) {
                        return true
                    }
                }
            }
            usleep(150_000)
        } while Date() < deadline
        return false
    }
}
