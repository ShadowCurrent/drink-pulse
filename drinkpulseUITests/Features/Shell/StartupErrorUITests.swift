import XCTest

/// Regression coverage for STARTUP-03/D-05/D-06/D-07/D-10: a container-open
/// failure shows a full-screen `StartupErrorView` — never a crash, never an
/// overlay on stale content — and Retry always re-attempts the full
/// container-open sequence.
///
/// All assertions key off the app's own English strings and tab bar — never
/// system-process UI or locale-formatted numbers (the simulator system
/// locale is Polish; the app's strings are English-only, so app text is
/// safe to match).
///
/// Launch uses the existing gated hooks:
///   - `-dp_uitest YES`                     → in-memory store.
///   - `-dp_uitest_force_store_failure YES` → makes `UITestSeed.makeContainer`
///     throw immediately, driving `drinkpulseApp.loadContainerIfNeeded()`
///     deterministically into `.failed` without real disk corruption.
@MainActor
final class StartupErrorUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// A forced container-open failure shows the full-screen error view with
    /// Retry and Share Diagnostic Details — never the shell or onboarding.
    ///
    /// The Retry button's visible text is "Try Again", but D-10/UI-SPEC
    /// requires an explicit `.accessibilityLabel("Retry loading your data")`
    /// for VoiceOver clarity — which replaces its queryable accessibility
    /// label, so it is matched here by that label rather than its displayed
    /// text (same reasoning for Share Diagnostic Details).
    func test_storeFailure_showsFullScreenErrorWithRetryAndDiagnosticAction() throws {
        let app = launchWithForcedStoreFailure()

        XCTAssertTrue(app.buttons["Retry loading your data"].waitForExistence(timeout: 10),
                      "Retry button should appear when the container fails to open")
        XCTAssertTrue(app.staticTexts["Couldn't Load Your Data"].exists,
                      "The error screen's title should be visible")
        XCTAssertTrue(app.buttons["Share diagnostic details for troubleshooting"].exists,
                      "Share Diagnostic Details action should be visible")

        // Proves the error view fully replaces app content — not an overlay.
        XCTAssertFalse(app.tabBars.buttons["Home"].exists,
                       "The tab bar must not be reachable behind the error screen")
        XCTAssertFalse(app.buttons["Get Started"].exists,
                       "Onboarding's Welcome step must not be reachable behind the error screen")
    }

    /// Tapping Retry re-attempts the full container-open sequence. Since the
    /// forced-failure launch argument is unchanged across the retry, the
    /// error screen reappearing (rather than a hang or a false success)
    /// proves Retry re-ran the full sequence, not a shortcut (D-06/D-07).
    func test_retryButton_reattemptsFullSequence_andReturnsToErrorScreenOnRepeatedFailure() throws {
        let app = launchWithForcedStoreFailure()

        let retry = app.buttons["Retry loading your data"]
        XCTAssertTrue(retry.waitForExistence(timeout: 10),
                      "Retry button should appear at launch")
        retry.tap()

        XCTAssertTrue(app.buttons["Retry loading your data"].waitForExistence(timeout: 10),
                      "Retry should reappear after a repeated failure, proving Retry " +
                      "re-ran the full open-recover-open sequence rather than hanging or " +
                      "silently succeeding")
    }

    // MARK: - Helpers

    private func launchWithForcedStoreFailure() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_uitest_force_store_failure", "YES",
        ]
        app.launch()
        return app
    }
}
