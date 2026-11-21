import XCTest

/// Review focus 1 (plan 0046): the hero shows today's level; the weekly alert shows only on the
/// rolling 7-day condition. Dataset `overweekly`: heavy days 1 and 2 days ago, nothing today.
@MainActor
final class TodayStatusUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_dataset", "overweekly",
        ]
        app.launch()
    }

    func test_overWeeklyLimit_showsAlert_andHeroKeepsTodaysStatus() throws {
        launchApp()
        XCTAssertTrue(app.navigationBars[UITestTabs.today].waitForExistence(timeout: 10))

        // The status label is part of the hero's one combined accessibility element (D0046-2).
        let hero = app.descendants(matching: .any)["today.hero"]
        XCTAssertTrue(hero.waitForExistence(timeout: 10), "Hero should be present")
        XCTAssertTrue(hero.label.contains("Within Limit"),
                      "Nothing logged today: hero status should be Within Limit, got '\(hero.label)'")
        XCTAssertFalse(hero.label.contains("Over Limit"),
                       "The hero must not show the weekly level, got '\(hero.label)'")

        let alert = app.descendants(matching: .any)["today.alert"]
        var attempts = 0
        while !alert.exists, attempts < 4 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Weekly alert should be shown")
        XCTAssertTrue(alert.label.contains("Over Weekly Limit"),
                      "Alert should read Over Weekly Limit, got '\(alert.label)'")
    }
}
