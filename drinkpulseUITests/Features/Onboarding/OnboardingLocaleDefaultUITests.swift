import XCTest

@MainActor
final class OnboardingLocaleDefaultUITests: XCTestCase {

    func test_onboarding_enUS_defaultsToUsFlOz() throws {
        let app = makeApp(locale: "en_US")
        app.launch()
        driveOnboardingToCompletion(in: app)
        assertVolumeUnitInSettings(app: app, contains: "US fl oz",
                                   failMessage: "en_US locale should default to 'US fl oz' in Settings")
    }

    func test_onboarding_deDE_defaultsToMillilitres() throws {
        let app = makeApp(locale: "de_DE")
        app.launch()
        driveOnboardingToCompletion(in: app)
        assertVolumeUnitInSettings(app: app, contains: "Millilitres",
                                   failMessage: "de_DE locale should default to 'Millilitres (ml)' in Settings")
    }

    // MARK: - Helpers

    private func makeApp(locale: String) -> XCUIApplication {
        let a = XCUIApplication()
        a.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_force_onboarding", "YES",
            "-AppleLocale", locale,
            "-AppleLanguages", "(en)",
        ]
        return a
    }

    private func driveOnboardingToCompletion(in app: XCUIApplication) {
        continueAfterFailure = false

        let welcomeGetStarted = app.buttons["Get Started"]
        XCTAssertTrue(welcomeGetStarted.waitForExistence(timeout: 10),
                      "Welcome step 'Get Started' button should appear at launch")
        welcomeGetStarted.tap()

        let profileContinue = app.buttons["Continue"]
        XCTAssertTrue(profileContinue.waitForExistence(timeout: 5),
                      "Profile step 'Continue' button should appear")
        profileContinue.tap()

        let guidelineContinue = app.buttons["Continue"]
        XCTAssertTrue(guidelineContinue.waitForExistence(timeout: 5),
                      "Guideline step 'Continue' button should appear")
        guidelineContinue.tap()

        let healthDone = app.buttons["Done"]
        XCTAssertTrue(healthDone.waitForExistence(timeout: 5),
                      "Apple Health step 'Done' button should appear")
        healthDone.tap()

        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10),
                      "Tab bar should appear after onboarding completion")
    }

    private func assertVolumeUnitInSettings(app: XCUIApplication,
                                            contains label: String,
                                            failMessage: String) {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5),
                      "Settings tab must be reachable")
        settingsTab.tap()

        let volumeUnitPicker = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Millilitres' OR label CONTAINS 'fl oz'")
        ).firstMatch
        XCTAssertTrue(volumeUnitPicker.waitForExistence(timeout: 5),
                      "Volume unit picker should be visible in Settings")
        XCTAssertTrue(volumeUnitPicker.label.contains(label),
                      "\(failMessage). Picker label was: '\(volumeUnitPicker.label)'")
    }
}
