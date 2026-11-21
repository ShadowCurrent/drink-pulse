import XCTest

/// Insights period controls, empty state and Health Impact copy (plan 0046, Task 6).
@MainActor
final class InsightsNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(dataset: String = "multiday") {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_dataset", dataset,
        ]
        app.launch()
        let tab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "Insights tab should be visible")
        tab.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5))
    }

    private var todayButton: XCUIElement { app.buttons["insights.nav.todayButton"] }
    private var previousButton: XCUIElement { app.buttons["insights.nav.previous"] }

    // D0046-8: the jump back is a toolbar "Today" button, shown only off the current period.
    func test_todayButton_appearsOffCurrentPeriod_andReturns() throws {
        launchApp()
        XCTAssertTrue(app.staticTexts["This week"].waitForExistence(timeout: 10))
        XCTAssertFalse(todayButton.exists, "No Today button on the current period")

        XCTAssertTrue(previousButton.waitForExistence(timeout: 5))
        previousButton.tap()
        XCTAssertTrue(app.staticTexts["Last week"].waitForExistence(timeout: 5))
        XCTAssertTrue(todayButton.waitForExistence(timeout: 5), "Today button should appear off the current period")

        todayButton.tap()
        XCTAssertTrue(app.staticTexts["This week"].waitForExistence(timeout: 5))
        XCTAssertTrue(todayButton.waitForNonExistence(timeout: 5), "Today button should go on the current period")
    }

    // D0046-9: the navigator is hidden in All; the chart stays.
    func test_allTimeScope_hidesNavigator_keepsChart() throws {
        launchApp()
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        XCTAssertTrue(previousButton.exists, "Week shows the navigator")
        picker.buttons["All"].tap()
        XCTAssertTrue(previousButton.waitForNonExistence(timeout: 5), "All hides the navigator")
        let chart = app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", "Alcohol Over Time")
        ).firstMatch
        XCTAssertTrue(chart.waitForExistence(timeout: 5), "All keeps the area chart")
    }

    // D0046-13: no events at all → one empty state with Log a Drink.
    func test_emptyStore_showsNoInsightsYet_andLogADrinkOpensAddDrink() throws {
        launchApp(dataset: "empty")
        XCTAssertTrue(app.staticTexts["No Insights Yet"].waitForExistence(timeout: 10))
        let log = app.buttons["empty.logADrink"]
        XCTAssertTrue(log.waitForExistence(timeout: 5))
        log.tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5))
    }

    // D0046-10 (owner): Heavy Days with its definition.
    func test_healthImpact_showsHeavyDaysWithDefinition() throws {
        launchApp()
        let heavy = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "Heavy Days")
        ).firstMatch
        var swipes = 0
        while !heavy.exists, swipes < 4 { app.swipeUp(); swipes += 1 }
        XCTAssertTrue(heavy.waitForExistence(timeout: 5), "Heavy Days cell should be present")
        let text = heavy.label + " " + (heavy.value as? String ?? "")
        XCTAssertTrue(text.contains("60 g or more in a day"), "Heavy Days should carry its definition, got '\(text)'")
    }

    // Review focus 3 (UI half): an older period keeps the hero total and never shows the empty
    // state. `multiday` has a drink at least every two days back to its oldest week, so no
    // reachable week is empty; the zero total of an empty period is pinned by
    // `InsightsViewModelTests.test_emptyRange_hasZeroTotalAndNoTrend` (plan 0046 review).
    func test_olderPeriod_showsTotal_notEmptyState() throws {
        launchApp()
        XCTAssertTrue(previousButton.waitForExistence(timeout: 10))
        for _ in 0..<3 where previousButton.isEnabled { previousButton.tap() }
        XCTAssertFalse(app.staticTexts["No Insights Yet"].exists, "An empty period is not the empty state")
        let total = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", " std")).firstMatch
        XCTAssertTrue(total.waitForExistence(timeout: 5), "The hero total should still render")
    }
}
