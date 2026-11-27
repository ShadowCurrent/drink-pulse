import XCTest

/// Plan 0050 (D0050-4, D0050-5): a period with no counted day shows "–" for both alcohol-free
/// values. Dataset `alcoholfreetoday`: the only log is a 0 % beer today, and today without
/// alcohol is not counted yet.
@MainActor
final class InsightsAlcoholFreePlaceholderUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_week_noCountedDay_showsDash() throws {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_dataset", "alcoholfreetoday",
        ]
        app.launch()

        let insightsTab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 10), "Insights tab should be visible")
        insightsTab.tap()
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10), "Period picker should be present")
        picker.buttons["Week"].tap()

        let freeDays = app.descendants(matching: .any)["Alcohol-Free Days: –"]
        XCTAssertTrue(freeDays.waitForExistence(timeout: 10),
                      "Alcohol-Free Days should read '–' when no day counts yet")
        let streak = app.descendants(matching: .any)["Longest Alcohol-Free Streak: –"]
        XCTAssertTrue(streak.waitForExistence(timeout: 5),
                      "Longest Alcohol-Free Streak should read '–' when no day counts yet")
    }
}
