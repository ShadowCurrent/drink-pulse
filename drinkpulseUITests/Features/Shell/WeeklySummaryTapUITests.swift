import XCTest

@MainActor
final class WeeklySummaryTapUITests: XCTestCase {

    func test_pendingOpenInsights_opensInsightsTab_onColdLaunch() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_pending_open_insights", "YES",
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 10),
                      "A cold launch with pendingOpenInsights pre-set should land directly on the Insights tab")
    }

    func test_weeklySummaryTap_opensInsightsTab_onWarmLaunch() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_warm_weekly_tap", "YES",
        ]
        app.launch()

        XCTAssertFalse(app.navigationBars["Insights"].exists,
                       "The app starts on Home, so the Insights tab must not be showing before the tap")

        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10),
                      "The app should reach the background after pressing Home")

        app.activate()

        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 10),
                      "A weekly-summary tap delivered while the app was backgrounded should land on the Insights tab")
    }
}
