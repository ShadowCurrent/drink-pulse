import XCTest

@MainActor
extension HistoryInteractionUITests {

    func openHistoryTab() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10),
                      "History tab should be accessible after launch")
        tab.tap()
    }

    func eventButton(containing substring: String) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", substring)
        ).firstMatch
    }

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

    func tapSegment(_ label: String) {
        let segment = app.segmentedControls.buttons[label]
        XCTAssertTrue(segment.waitForExistence(timeout: 5),
                      "History segment '\(label)' should exist")
        segment.tap()
    }

    func currentDayNumber() -> String {
        String(Calendar.current.component(.day, from: .now))
    }

    func calendarDayCell(forTodayNumber number: String) -> XCUIElement {
        let withGrams = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", " g")
        ).firstMatch
        if withGrams.exists { return withGrams }
        return app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", number)
        ).firstMatch
    }

    func calendarDayCellForToday() -> XCUIElement {
        let number = currentDayNumber()
        return app.buttons.matching(
            NSPredicate(format: "label MATCHES %@", "^\(number)\\D.*")
        ).firstMatch
    }

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
