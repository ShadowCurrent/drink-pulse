import XCTest

/// Plan 0050 (D0050-5): with only a 0 % beer logged today, today is not counted yet, so the
/// Today alcohol-free tiles read 0 days (the pre-plan code showed a 366-day streak and 1 day).
@MainActor
final class DashboardAlcoholFreeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_zeroPercentToday_streakAndMonthAreZero() throws {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_dataset", "alcoholfreetoday",
        ]
        app.launch()
        XCTAssertTrue(app.navigationBars[UITestTabs.today].waitForExistence(timeout: 10),
                      "Today navigation bar should appear after launch")

        let streak = element(beginningWith: "Alcohol-Free Streak")
        scrollToFind(streak)
        XCTAssertTrue(streak.waitForExistence(timeout: 5), "Streak tile missing")
        XCTAssertTrue(readsZeroDays(streak.label), "Streak tile should read 0 days, got '\(streak.label)'")

        let month = element(beginningWith: "Alcohol-Free This Month")
        XCTAssertTrue(month.waitForExistence(timeout: 5), "Month tile missing")
        XCTAssertTrue(readsZeroDays(month.label), "Month tile should read 0 days, got '\(month.label)'")
    }

    /// "0 days" as a whole number (not "10 days" or "366 days").
    private func readsZeroDays(_ label: String) -> Bool {
        label.range(of: #"(^|\D)0 days"#, options: .regularExpression) != nil
    }

    private func element(beginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch
    }

    private func scrollToFind(_ element: XCUIElement) {
        var attempts = 0
        while !element.isHittable, attempts < 4 {
            app.swipeUp()
            attempts += 1
        }
    }
}
