import XCTest

@MainActor
final class OnboardingAuthorityUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_midSessionProfileDeletion_staysOnRootShell_doesNotResetToOnboarding() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_onboarding_done", "YES",
            "-dp_uitest_delete_profile_midsession", "YES",
        ]
        app.launch()

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Home tab should remain present after a mid-session " +
                      "profile deletion — onboardingDone alone gates the shell")

        XCTAssertFalse(app.buttons["Get Started"].exists,
                       "OnboardingView's 'Get Started' button must never " +
                       "reappear after a mid-session profile deletion")
    }
}
