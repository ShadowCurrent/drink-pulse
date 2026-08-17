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
}
