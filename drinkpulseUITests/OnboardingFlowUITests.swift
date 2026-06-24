import XCTest

/// End-to-end coverage of the Onboarding walkthrough (plan-0032, step 6).
///
/// Complements `OnboardingLocaleDefaultUITests` (which only proves the
/// locale → default-unit mapping). This file asserts:
///   - the full 3-step walkthrough (Welcome → Profile → Guideline → Finish)
///     lands on the Home (Dashboard) tab;
///   - the "Skip all setup" path from Welcome reaches the app;
///   - profile inputs chosen in onboarding (biological sex + guideline) carry
///     into Settings.
///
/// All assertions key off the app's own English strings, navigation bars, tab
/// bars and picker labels — never on system-process UI or locale-formatted
/// numbers (the simulator system locale is Polish; the app's strings are
/// English-only, so app text is safe to match).
///
/// Launch uses the existing gated hooks:
///   - `-dp_uitest YES`          → in-memory store (real user store untouched).
///   - `-dp_force_onboarding YES`→ always show OnboardingView, skip seeding
///                                 (onboarding creates the profile itself).
@MainActor
final class OnboardingFlowUITests: XCTestCase {

    // MARK: - Tests

    /// Walking all three steps to completion lands on the Home tab.
    func test_fullWalkthrough_landsOnHome() throws {
        let app = launchApp()

        // Step 1: Welcome — "Get Started" (onboarding.welcome.cta).
        tapWelcomeGetStarted(in: app)

        // Step 2: Profile — pick a sex, then "Continue" (onboarding.step.continue).
        selectSex(in: app, label: "Female")
        let profileContinue = app.buttons["Continue"]
        XCTAssertTrue(profileContinue.waitForExistence(timeout: 5),
                      "Profile step 'Continue' button should appear")
        profileContinue.tap()

        // Step 3: Guideline — pick a non-default guideline, then "Get Started"
        // (onboarding.guideline.done).
        selectGuideline(in: app, named: "Germany (DHS)")
        let guidelineDone = app.buttons["Get Started"]
        XCTAssertTrue(guidelineDone.waitForExistence(timeout: 5),
                      "Guideline step 'Get Started' button should appear")
        guidelineDone.tap()

        // Lands on Home: tab bar present and Home tab selected.
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Tab bar with Home tab should appear after onboarding completion")
        XCTAssertTrue(homeTab.isSelected,
                      "Home tab should be the selected tab after onboarding")
        let homeNav = app.navigationBars["Home"]
        XCTAssertTrue(homeNav.waitForExistence(timeout: 5),
                      "Home (Dashboard) navigation bar should be visible after onboarding")
    }

    /// "Skip all setup" on the Welcome step still reaches the app shell.
    func test_skipAllFromWelcome_reachesApp() throws {
        let app = launchApp()

        let skipAll = app.buttons["Skip all setup"]
        XCTAssertTrue(skipAll.waitForExistence(timeout: 10),
                      "Welcome step 'Skip all setup' button should appear at launch")
        skipAll.tap()

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Tab bar should appear after skipping all onboarding setup")
    }

    /// Sex + guideline chosen during onboarding are reflected in Settings.
    func test_profileInputs_carryIntoSettings() throws {
        let app = launchApp()

        tapWelcomeGetStarted(in: app)
        selectSex(in: app, label: "Female")
        let profileContinue = app.buttons["Continue"]
        XCTAssertTrue(profileContinue.waitForExistence(timeout: 5),
                      "Profile step 'Continue' button should appear")
        profileContinue.tap()

        selectGuideline(in: app, named: "Germany (DHS)")
        let guidelineDone = app.buttons["Get Started"]
        XCTAssertTrue(guidelineDone.waitForExistence(timeout: 5),
                      "Guideline step 'Get Started' button should appear")
        guidelineDone.tap()

        // Navigate to Settings.
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10),
                      "Settings tab must be reachable after onboarding")
        settingsTab.tap()

        // Guideline row is a Button whose label is the guideline's display name.
        // Asserting it first also confirms the Settings form has rendered.
        let guidelineRow = app.buttons["Germany (DHS)"]
        XCTAssertTrue(guidelineRow.waitForExistence(timeout: 8),
                      "Guideline chosen in onboarding (Germany (DHS)) should carry into Settings")

        // Sex menu Picker is a Button whose label reflects the selection
        // ("Female" / "Male" via settings.sex.male / settings.sex.female).
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

    /// Launches the app showing onboarding unconditionally on an in-memory store.
    private func launchApp() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        // -dp_force_onboarding YES: always show OnboardingView and skip seeding,
        // so onboarding creates the profile itself. -dp_uitest YES: in-memory
        // store so the real user store is never touched.
        app.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_force_onboarding", "YES",
        ]
        app.launch()
        return app
    }

    /// Taps the Welcome step's "Get Started" CTA (onboarding.welcome.cta).
    private func tapWelcomeGetStarted(in app: XCUIApplication) {
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 10),
                      "Welcome step 'Get Started' button should appear at launch")
        getStarted.tap()
    }

    /// Selects a value on the Profile step's segmented sex Picker.
    /// The segmented control exposes its options as buttons labelled
    /// "Male" / "Female" (settings.sex.male / settings.sex.female).
    private func selectSex(in app: XCUIApplication, label: String) {
        let option = app.buttons[label]
        XCTAssertTrue(option.waitForExistence(timeout: 5),
                      "Profile step sex option '\(label)' should be selectable")
        option.tap()
    }

    /// Selects a guideline row on the Guideline step by its display name.
    /// Each row is a List button whose accessibility label combines the
    /// guideline name with its threshold summary, so match by CONTAINS.
    private func selectGuideline(in app: XCUIApplication, named name: String) {
        let row = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", name)
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5),
                      "Guideline step should offer the '\(name)' option")
        row.tap()
    }
}
