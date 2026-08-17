import XCTest

@MainActor
final class StartupErrorUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_storeFailure_showsFullScreenErrorWithRetryAndDiagnosticAction() throws {
        let app = launchWithForcedStoreFailure()

        XCTAssertTrue(app.buttons["Retry loading your data"].waitForExistence(timeout: 10),
                      "Retry button should appear when the container fails to open")
        XCTAssertTrue(app.staticTexts["Couldn't Load Your Data"].exists,
                      "The error screen's title should be visible")
        XCTAssertTrue(app.buttons["Share diagnostic details for troubleshooting"].exists,
                      "Share Diagnostic Details action should be visible")

        XCTAssertFalse(app.tabBars.buttons["Home"].exists,
                       "The tab bar must not be reachable behind the error screen")
        XCTAssertFalse(app.buttons["Get Started"].exists,
                       "Onboarding's Welcome step must not be reachable behind the error screen")
    }

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
