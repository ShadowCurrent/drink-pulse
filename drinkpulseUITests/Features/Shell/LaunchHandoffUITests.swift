import XCTest

@MainActor
final class LaunchHandoffUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_onboardedLaunch_landsOnHomeWithinTimeout() throws {
        let app = launchOnboarded()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10),
                      "An already-onboarded cold launch should land on the Home tab")
    }

    func test_freshLaunch_landsOnOnboardingWelcomeWithinTimeout() throws {
        let app = launchFreshOnboarding()

        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 10),
                      "A fresh cold launch should land on Onboarding's Welcome step")
    }

    // MARK: - Helpers

    private func launchOnboarded() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_onboarding_done", "YES",
        ]
        app.launch()
        return app
    }

    private func launchFreshOnboarding() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_force_onboarding", "YES",
        ]
        app.launch()
        return app
    }
}
