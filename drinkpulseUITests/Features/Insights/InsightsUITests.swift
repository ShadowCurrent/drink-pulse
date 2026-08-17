import XCTest

@MainActor
final class InsightsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_dataset", "multiday",
        ]
        app.launch()
    }

    // MARK: - Period picker switches the range

    func test_periodPicker_switchesRange_changesHeroTotal() throws {
        launchApp()
        openInsights()

        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10),
                      "Period segmented control should be present on Insights")

        let weekButton = picker.buttons["Week"]
        XCTAssertTrue(weekButton.waitForExistence(timeout: 5),
                      "Period picker should offer a 'Week' segment")
        weekButton.tap()
        let weekTotal = heroTotalLabel()
        XCTAssertFalse(weekTotal.isEmpty, "Hero Total value should render for the Week scope")

        let yearButton = picker.buttons["Year"]
        XCTAssertTrue(yearButton.waitForExistence(timeout: 5),
                      "Period picker should offer a 'Year' segment")
        yearButton.tap()

        let changed = waitUntil(timeout: 5) { [weekTotal] in
            let now = self.heroTotalLabel()
            return !now.isEmpty && now != weekTotal
        }
        XCTAssertTrue(changed,
                      "Switching Week → Year should change the hero Total "
                      + "(Week='\(weekTotal)', Year='\(heroTotalLabel())')")
    }

    // MARK: - Previous-period navigation available on first load

    func test_weekScope_prevPeriodEnabledOnFirstLoad_andNavigates() throws {
        launchApp()
        openInsights()

        XCTAssertTrue(app.staticTexts["This week"].waitForExistence(timeout: 10),
                      "Insights should open on the current week")

        let prev = app.buttons["Previous period"]
        XCTAssertTrue(prev.waitForExistence(timeout: 5),
                      "Previous-period arrow should be present")
        XCTAssertTrue(prev.isEnabled,
                      "Prev arrow must be enabled on first load — prior weeks have data")

        prev.tap()
        XCTAssertTrue(app.staticTexts["Last week"].waitForExistence(timeout: 5),
                      "Tapping prev from the current week should navigate to 'Last week'")
    }

    // MARK: - Area chart + weekday bar chart present

    func test_areaChartAndWeekdayChart_arePresent() throws {
        launchApp()
        openInsights()

        let areaChart = firstElement(withLabel: "Alcohol Over Time")
        XCTAssertTrue(areaChart.waitForExistence(timeout: 10),
                      "Area chart ('Alcohol Over Time') should be present on Insights")

        let weekdayHeader = app.staticTexts["Weekday Patterns"]
        if !weekdayHeader.waitForExistence(timeout: 3) {
            app.swipeUp()
        }
        XCTAssertTrue(weekdayHeader.waitForExistence(timeout: 5),
                      "Weekday bar chart header ('Weekday Patterns') should be present")
    }

    // MARK: - Hero card value

    func test_heroCard_showsTotalValue() throws {
        launchApp()
        openInsights()

        let totalHeader = firstElement(withLabel: "Total")
        XCTAssertTrue(totalHeader.waitForExistence(timeout: 10),
                      "Hero card 'Total' eyebrow should be present on Insights")

        let value = heroTotalLabel()
        XCTAssertFalse(value.isEmpty,
                       "Hero card should render a Total value reflecting consumption")
        XCTAssertTrue(value.contains("std"),
                      "Hero Total should carry the std-drinks unit token, got '\(value)'")
    }

    // MARK: - Hero card height stability across periods

    func test_heroCard_holdsHeight_whenSwitchingToAllTimeScope() throws {
        launchApp()
        openInsights()

        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10),
                      "Period segmented control should be present on Insights")

        let areaChart = firstElement(withLabel: "Alcohol Over Time")
        XCTAssertTrue(areaChart.waitForExistence(timeout: 10),
                      "Area chart should be present under the hero card")
        let weekChartY = areaChart.frame.origin.y

        let allButton = picker.buttons["All"]
        XCTAssertTrue(allButton.waitForExistence(timeout: 5),
                      "Period picker should offer an 'All' segment")
        allButton.tap()

        XCTAssertTrue(areaChart.waitForExistence(timeout: 5),
                      "Area chart should still be present in the All-time scope")
        let allChartY = areaChart.frame.origin.y

        XCTAssertEqual(weekChartY, allChartY, accuracy: 1.0,
                       "Hero card height must not change between Week and All scopes "
                       + "(Week chart y=\(weekChartY), All chart y=\(allChartY))")
    }

    // MARK: - Health metrics rows

    func test_healthMetrics_rowsArePresent() throws {
        launchApp()
        openInsights()

        let healthHeader = app.staticTexts["Health Impact"]
        if !healthHeader.waitForExistence(timeout: 3) {
            app.swipeUp()
        }
        XCTAssertTrue(healthHeader.waitForExistence(timeout: 10),
                      "Health Impact card header should be present on Insights")

        let caloriesCell = firstElement(beginningWith: "Alcohol Calories")
        XCTAssertTrue(caloriesCell.waitForExistence(timeout: 5),
                      "Health metrics should include an 'Alcohol Calories' cell")

        let drinkFreeCell = firstElement(beginningWith: "Drink-Free Days")
        XCTAssertTrue(drinkFreeCell.waitForExistence(timeout: 5),
                      "Health metrics should include a 'Drink-Free Days' cell")
    }

    // MARK: - Guideline comparison card

    func test_guidelineComparison_cardIsPresent() throws {
        launchApp()
        openInsights()

        let header = app.staticTexts["Guideline Comparison"]
        for _ in 0..<3 where !header.exists {
            app.swipeUp()
        }
        XCTAssertTrue(header.waitForExistence(timeout: 10),
                      "Guideline Comparison card header should be present on Insights")

        let limitRow = firstElement(containing: "of limit")
        XCTAssertTrue(limitRow.waitForExistence(timeout: 5),
                      "Guideline Comparison should contain at least one '... of limit' row")
    }

    // MARK: - Helpers

    private func openInsights() {
        let insightsTab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 10),
                      "Insights tab button should be visible after launch")
        insightsTab.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5),
                      "Insights screen navigation bar should appear")
    }

    private func heroTotalLabel() -> String {
        let candidate = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "std")
        ).firstMatch
        return candidate.exists ? candidate.label : ""
    }

    private func firstElement(withLabel label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", label)
        ).firstMatch
    }

    private func firstElement(beginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch
    }

    private func firstElement(containing needle: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", needle)
        ).firstMatch
    }

    private func waitUntil(timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            usleep(150_000)
        }
        return condition()
    }
}
