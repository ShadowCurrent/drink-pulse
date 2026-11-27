import XCTest

@MainActor
final class OnboardingFlowUITests: XCTestCase {

    // MARK: - Tests

    func test_fullWalkthrough_landsOnHome() throws {
        let app = launchApp()

        tapWelcomeGetStarted(in: app)

        OnboardingWalk.chooseSex("Female", in: app)
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

        let homeTab = app.tabBars.buttons[UITestTabs.today]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Tab bar with Home tab should appear after onboarding completion")
        XCTAssertTrue(homeTab.isSelected,
                      "Home tab should be the selected tab after onboarding")
        let homeNav = app.navigationBars[UITestTabs.today]
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
        // The Back button stays laid out on step 1 (one header height, D0048-9) but is hidden from
        // accessibility there, so it must leave the element tree.
        XCTAssertTrue(app.buttons["Back"].waitForNonExistence(timeout: 3),
                      "Back button should not be exposed on the first step")
    }

    func test_profileInputs_carryIntoSettings() throws {
        let app = launchApp()

        tapWelcomeGetStarted(in: app)
        OnboardingWalk.chooseSex("Female", in: app)
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

        // Settings guideline is a navigation-link Picker (plan 0043): label "Guideline", the
        // choice in its label or value.
        let guidelineRow = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Guideline'")
        ).firstMatch
        XCTAssertTrue(guidelineRow.waitForExistence(timeout: 8),
                      "Settings guideline row should be visible")
        let guidelineText = "\(guidelineRow.label) \(guidelineRow.value as? String ?? "")"
        XCTAssertTrue(guidelineText.contains("Germany (DHS)"),
                      "Guideline chosen in onboarding (Germany (DHS)) should carry into Settings, got '\(guidelineText)'")

        let sexPicker = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Female' OR label CONTAINS 'Male'")
        ).firstMatch
        XCTAssertTrue(sexPicker.waitForExistence(timeout: 5),
                      "Biological-sex picker should be visible in Settings")
        XCTAssertTrue(sexPicker.label.contains("Female"),
                      "Sex chosen in onboarding (Female) should carry into Settings. " +
                      "Picker label was: '\(sexPicker.label)'")
    }

    func test_continueDisabled_untilSexChosen() throws {
        let app = launchApp()
        tapWelcomeGetStarted(in: app)

        let profileContinue = app.buttons["Continue"]
        XCTAssertTrue(profileContinue.waitForExistence(timeout: 5), "About You 'Continue' should appear")
        XCTAssertFalse(profileContinue.isEnabled, "Continue must be disabled until a sex is chosen")

        OnboardingWalk.chooseSex("Male", in: app)
        XCTAssertTrue(profileContinue.isEnabled, "Continue should be enabled once a sex is chosen")
    }

    /// Steps change only through the buttons: a swipe moves no page, even with a sex chosen. The
    /// paged `TabView` that offered swiping reloaded its pages when a sex was chosen, which made
    /// About You flicker, so it was replaced by a direct step view.
    func test_swipe_doesNotChangeStep() throws {
        let app = launchApp()

        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 10), "Welcome should be shown")
        app.swipeLeft()
        XCTAssertTrue(getStarted.waitForExistence(timeout: 2), "A swipe must not leave Welcome")

        getStarted.tap()
        let aboutYou = app.staticTexts["About You"]
        XCTAssertTrue(aboutYou.waitForExistence(timeout: 5), "Get Started should show About You")
        OnboardingWalk.chooseSex("Female", in: app)
        // Swipe on the heading: the screen centre is on the sex control.
        aboutYou.swipeLeft()
        XCTAssertTrue(aboutYou.waitForExistence(timeout: 2), "A swipe must not leave About You")
        XCTAssertFalse(app.staticTexts["Your Guideline"].exists, "A swipe must not reach Your Guideline")

        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Your Guideline"].waitForExistence(timeout: 5),
                      "Continue should show Your Guideline")
        app.buttons["Back"].tap()
        XCTAssertTrue(aboutYou.waitForExistence(timeout: 5), "Back should return to About You")
    }

    /// Date of birth was removed on 2026-11-27 (quick 261127-l7y): About You asks only for sex,
    /// and choosing one still leads on to Your Guideline.
    func test_profileStep_hasNoDateOfBirthControl() throws {
        let app = launchApp()
        tapWelcomeGetStarted(in: app)

        XCTAssertTrue(app.staticTexts["About You"].waitForExistence(timeout: 5), "About You should be shown")
        XCTAssertFalse(app.buttons["Add Date of Birth"].exists, "No 'Add Date of Birth' button")
        XCTAssertEqual(app.datePickers.count, 0, "No date picker on About You")
        let dobLabel = NSPredicate(format: "label CONTAINS[c] 'Date of Birth'")
        XCTAssertFalse(app.descendants(matching: .any).matching(dobLabel).firstMatch.exists,
                       "No element mentions a date of birth")

        OnboardingWalk.chooseSex("Female", in: app)
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Your Guideline"].waitForExistence(timeout: 5),
                      "Continue should still show Your Guideline")
    }

    func test_pendingOpenInsights_waitsForOnboarding_thenOpensInsights() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_force_onboarding", "YES",
            "-dp_uitest_pending_open_insights", "YES",
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 10),
                      "Onboarding should be shown although an Insights open is pending")
        // D0048-3: no tab change or sheet under the cover (UI-test probe inside the cover).
        let shellState = app.descendants(matching: .any)["dp_shell_state"]
        XCTAssertTrue(shellState.waitForExistence(timeout: 5), "Shell state probe should exist under -dp_uitest")
        XCTAssertEqual(shellState.label, "tab=home sheet=false",
                       "The pending Insights open must wait while onboarding is up")
        OnboardingWalk.walkToHealth(in: app)
        app.buttons["Done"].tap()

        let insights = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insights.waitForExistence(timeout: 10), "The tab bar should appear after Done")
        let selected = NSPredicate(format: "isSelected == true")
        expectation(for: selected, evaluatedWith: insights)
        waitForExpectations(timeout: 5)
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
