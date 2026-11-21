import XCTest

/// History list as one section per day with the day total in the header (plan 0045, Task 2).
@MainActor
final class HistoryDaySectionsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(dataset: String) {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
            "-dp_uitest_dataset", dataset,
        ]
        app.launch()
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should exist")
        tab.tap()
    }

    private var dayHeaders: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "history.dayHeader")
    }

    private func visibleHeaderLabels() -> [String] {
        dayHeaders.allElementsBoundByIndex.map(\.label)
    }

    func test_dayHeader_showsDrinkCountAndTotal() throws {
        launchApp(dataset: "paginationstress")
        let today = dayHeaders.matching(NSPredicate(format: "label BEGINSWITH %@", "Today")).firstMatch
        XCTAssertTrue(today.waitForExistence(timeout: 10), "Today's day header should exist")
        XCTAssertTrue(today.label.contains("3 drinks"),
                      "Today's header should count the three seeded drinks, got '\(today.label)'")
    }

    /// Review focus 1: every loaded day is complete, so no header shows a partial total.
    func test_oldestLoadedDay_headerCountsWholeDay() throws {
        launchApp(dataset: "paginationstress")
        XCTAssertTrue(dayHeaders.firstMatch.waitForExistence(timeout: 10), "Day headers should exist")

        var labels = Set(visibleHeaderLabels())
        let marker = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "999 ml")).firstMatch
        for _ in 0..<30 where !(marker.exists && labels.count >= 21) {
            app.swipeUp()
            labels.formUnion(visibleHeaderLabels())
        }
        labels.formUnion(visibleHeaderLabels())

        XCTAssertFalse(labels.contains { $0.contains("2 drinks") },
                       "No day may show a partial total across a page edge, got \(labels.sorted())")
        XCTAssertEqual(labels.filter { $0.contains("3 drinks") }.count, 20,
                       "The twenty seeded days should each show 3 drinks, got \(labels.sorted())")
        XCTAssertEqual(labels.filter { $0.contains("1 drink") && !$0.contains("1 drinks") }.count, 1,
                       "The 40-days-ago marker day should show 1 drink, got \(labels.sorted())")
    }

    func test_segmentPicker_isInNavigationBar() throws {
        launchApp(dataset: "paginationstress")
        let bar = app.navigationBars["History"]
        XCTAssertTrue(bar.waitForExistence(timeout: 10), "History navigation bar should exist")
        let picker = bar.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "The List / Calendar picker should be in the bar")
        XCTAssertTrue(picker.buttons["List"].exists, "Picker should offer List")
        XCTAssertTrue(picker.buttons["Calendar"].exists, "Picker should offer Calendar")
    }

    func test_emptyHistory_logADrink_opensAddDrink() throws {
        launchApp(dataset: "empty")
        XCTAssertTrue(app.staticTexts["No Drinks Yet"].waitForExistence(timeout: 10),
                      "An empty History should show the empty state")
        let logButton = app.buttons["Log a Drink"]
        XCTAssertTrue(logButton.exists, "The empty state should offer Log a Drink")
        logButton.tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5),
                      "Log a Drink should open the Add Drink sheet")
    }
}
