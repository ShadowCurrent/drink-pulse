import XCTest

/// ENGG-07 (phase-01, v1.1): tapping the weekly-summary notification must
/// route a cold launch straight to the Insights tab, via
/// `RootShellView.openInsightsIfPending()` consuming the persisted
/// `AppStorageKeys.pendingOpenInsights` flag set by `NotificationActionHandler`.
///
/// `UNNotificationResponse` has no public initializer XCTest can construct, so
/// a real OS notification-tap gesture cannot be simulated here. Instead, this
/// test pre-sets the exact same flag a real tap would set — via the
/// launch-argument-gated `UITestSeed.seedPendingOpenInsights` hook — and
/// asserts the app lands on the Insights tab with no tap performed by the
/// test itself. The code path exercised (`openInsightsIfPending()`) is
/// identical to what a real notification tap drives; only the origin of the
/// pre-set flag differs.
///
/// Locale-independent: asserts on the app's own English navigation-bar title
/// (`InsightsView`'s `String(localized: "tab.insights")`, value "Insights"),
/// never on a tab-bar button's mere existence — every tab button always
/// exists regardless of which tab is selected, so only the navigation bar
/// proves Insights is actually the active tab.
@MainActor
final class WeeklySummaryTapUITests: XCTestCase {

    /// A cold launch with the pending-open-insights flag pre-set lands
    /// directly on the Insights tab, with no tap performed by the test.
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
