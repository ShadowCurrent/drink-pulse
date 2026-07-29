import XCTest

/// Regression coverage for LAUNCH-01 (Phase 4, branded static launch screen).
///
/// The real launch screen is pre-process, OS-rendered `UILaunchScreen`
/// config (Info.plist `UIImageName`/`UIColorName` resolved against the Asset
/// Catalog) -- XCUITest only attaches once the app process has started, i.e.
/// strictly after the real launch screen has already rendered and handed
/// off. Neither test below asserts anything about the launch screen itself;
/// they exist solely to prove Task 1's build-setting change (switching the
/// app target from a generated Info.plist to a standalone
/// `drinkpulse/Info.plist`, per Pattern 2) introduces zero regression to
/// normal app launch into either of the app's two possible first live
/// frames (onboarding or the Dashboard).
///
/// All assertions key off the app's own English strings and tab bar --
/// never system-process UI or locale-formatted numbers (the simulator
/// system locale is Polish; the app's strings are English-only, so app text
/// is safe to match).
@MainActor
final class LaunchHandoffUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// An already-onboarded launch lands on the Home tab within a 10-second
    /// timeout -- the app's first live frame when `onboardingDone` is true.
    func test_onboardedLaunch_landsOnHomeWithinTimeout() throws {
        let app = launchOnboarded()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10),
                      "An already-onboarded cold launch should land on the Home tab")
    }

    /// A fresh (never-onboarded) launch lands on Onboarding's Welcome step
    /// within a 10-second timeout -- the app's other possible first live
    /// frame when `onboardingDone` is false.
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
