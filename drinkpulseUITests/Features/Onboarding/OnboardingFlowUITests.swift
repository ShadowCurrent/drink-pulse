import XCTest

@MainActor
final class OnboardingFlowUITests: XCTestCase {

    // MARK: - Tests

    func test_fullWalkthrough_landsOnHome() throws {
        let app = launchApp()

        tapWelcomeGetStarted(in: app)

        selectSex(in: app, label: "Female")
        let profileContinue = app.buttons["Continue"]
        XCTAssertTrue(profileContinue.waitForExistence(timeout: 5),
                      "Profile step 'Continue' button should appear")
        profileContinue.tap()

        selectGuideline(in: app, named: "Germany (DHS)")
        let guidelineContinue = app.buttons["Continue"]
        XCTAssertTrue(guidelineContinue.waitForExistence(timeout: 5),
                      "Guideline step 'Continue' button should appear")
        guidelineContinue.tap()

        finishHealthStep(in: app)

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Tab bar with Home tab should appear after onboarding completion")
        XCTAssertTrue(homeTab.isSelected,
                      "Home tab should be the selected tab after onboarding")
        let homeNav = app.navigationBars["Home"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5),
                      "Home (Dashboard) navigation bar should be visible after onboarding")
    }

    func test_backButton_returnsToPreviousStep() throws {
        let app = launchApp()

        tapWelcomeGetStarted(in: app)
        let profileContinue = app.buttons["Continue"]
        XCTAssertTrue(profileContinue.waitForExistence(timeout: 5),
                      "Profile step should be reached")

        let back = app.buttons["Back"]
        XCTAssertTrue(back.waitForExistence(timeout: 5),
                      "Back button should appear past the first step")
        back.tap()

        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5),
                      "Tapping Back from Profile should return to the Welcome step")
        XCTAssertFalse(app.buttons["Back"].exists,
                       "Back button should not be present on the first step")
    }

    func test_profileInputs_carryIntoSettings() throws {
        let app = launchApp()

        tapWelcomeGetStarted(in: app)
        selectSex(in: app, label: "Female")
        let profileContinue = app.buttons["Continue"]
        XCTAssertTrue(profileContinue.waitForExistence(timeout: 5),
                      "Profile step 'Continue' button should appear")
        profileContinue.tap()

        selectGuideline(in: app, named: "Germany (DHS)")
        let guidelineContinue = app.buttons["Continue"]
        XCTAssertTrue(guidelineContinue.waitForExistence(timeout: 5),
                      "Guideline step 'Continue' button should appear")
        guidelineContinue.tap()

        finishHealthStep(in: app)

        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10),
                      "Settings tab must be reachable after onboarding")
        settingsTab.tap()

        let guidelineRow = app.buttons["Germany (DHS)"]
        XCTAssertTrue(guidelineRow.waitForExistence(timeout: 8),
                      "Guideline chosen in onboarding (Germany (DHS)) should carry into Settings")

        let sexPicker = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Female' OR label CONTAINS 'Male'")
        ).firstMatch
        XCTAssertTrue(sexPicker.waitForExistence(timeout: 5),
                      "Biological-sex picker should be visible in Settings")
        XCTAssertTrue(sexPicker.label.contains("Female"),
                      "Sex chosen in onboarding (Female) should carry into Settings. " +
                      "Picker label was: '\(sexPicker.label)'")
    }

    // MARK: - Helpers

    private func launchApp() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_force_onboarding", "YES",
        ]
        app.launch()
        return app
    }

    private func tapWelcomeGetStarted(in app: XCUIApplication) {
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 10),
                      "Welcome step 'Get Started' button should appear at launch")
        getStarted.tap()
    }

    private func selectSex(in app: XCUIApplication, label: String) {
        let option = app.buttons[label]
        XCTAssertTrue(option.waitForExistence(timeout: 5),
                      "Profile step sex option '\(label)' should be selectable")
        option.tap()
    }

    private func finishHealthStep(in app: XCUIApplication) {
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5),
                      "Apple Health step 'Done' button should appear as the final step")
        done.tap()
    }

    private func selectGuideline(in app: XCUIApplication, named name: String) {
        let row = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", name)
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5),
                      "Guideline step should offer the '\(name)' option")
        row.tap()
    }
}
