import XCTest

@MainActor
final class LaunchHandoffUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_onboardedLaunch_landsOnHomeWithinTimeout() throws {
        let app = launchOnboarded()

        XCTAssertTrue(app.tabBars.buttons[UITestTabs.today].waitForExistence(timeout: 10),
                      "An already-onboarded cold launch should land on the Home tab")
    }

    func test_freshLaunch_landsOnOnboardingWelcomeWithinTimeout() throws {
        let app = launchFreshOnboarding()

        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 10),
                      "A fresh cold launch should land on Onboarding's Welcome step")
        // The shell sits under the onboarding cover (D0048-1); its tab bar must not be usable.
        XCTAssertFalse(app.tabBars.buttons[UITestTabs.today].isHittable,
                       "Today must not be reachable while onboarding is shown")
    }

    func test_onboardingDone_landsOnToday_andCoverIsGone() throws {
        let app = launchFreshOnboarding()

        OnboardingWalk.walkToHealth(in: app)
        app.buttons["Done"].tap()

        let today = app.tabBars.buttons[UITestTabs.today]
        XCTAssertTrue(today.waitForExistence(timeout: 10), "Today should be shown after Done")
        XCTAssertTrue(app.buttons["Get Started"].waitForNonExistence(timeout: 5),
                      "The onboarding cover should be gone after Done")
        XCTAssertTrue(today.isHittable, "Today should be usable after Done")
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
