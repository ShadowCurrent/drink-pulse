import XCTest

/// Phase-01 (v1.1): the Weekly Summary opt-in shares the 4th onboarding step
/// (`HealthStep`) with the Apple Health opt-in, but writes an independent
/// `dp_weekly_summary_enabled` flag (D-06). This walks Welcome → Profile →
/// Guideline → Apple Health/Weekly Summary, proves the Weekly Summary toggle
/// can be switched on while the Health toggle stays off, and confirms the
/// on-state is reflected in Settings immediately after finishing onboarding
/// — no separate action required (ENGG-02).
///
/// Locale-independent: assertions key off the app's English labels (English-
/// only by product rule) and the Switch's numeric value ("0"/"1"), never on
/// system-process UI or localized system labels.
///
/// Launch hooks:
///   - `-dp_uitest YES`           → in-memory store + non-prompting stubs.
///   - `-dp_force_onboarding YES`  → always show OnboardingView, skip seeding.
@MainActor
final class OnboardingWeeklySummaryUITests: XCTestCase {

    /// The Weekly Summary toggle turns on independently of the Health toggle,
    /// and the on-state carries into Settings with no extra tap needed there.
    func test_weeklySummaryToggle_independentOfHealthToggle_andReflectedInSettingsAfterDone() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_force_onboarding", "YES",
        ]
        app.launch()

        // Welcome → Profile.
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 10),
                      "Welcome step should appear at launch")
        getStarted.tap()

        // Profile → Guideline.
        let profileContinue = app.buttons["Continue"]
        XCTAssertTrue(profileContinue.waitForExistence(timeout: 5),
                      "Profile step 'Continue' should appear")
        profileContinue.tap()

        // Guideline → Apple Health / Weekly Summary.
        let guidelineContinue = app.buttons["Continue"]
        XCTAssertTrue(guidelineContinue.waitForExistence(timeout: 5),
                      "Guideline step 'Continue' should appear")
        guidelineContinue.tap()

        // Step 4: both toggles start off.
        let healthToggle = app.switches["Write to Apple Health"]
        let weeklySummaryToggle = app.switches["Weekly check-in"]
        XCTAssertTrue(healthToggle.waitForExistence(timeout: 5),
                      "Apple Health toggle should appear as the 4th step")
        XCTAssertTrue(weeklySummaryToggle.waitForExistence(timeout: 5),
                      "Weekly Summary toggle should appear as the 4th step")
        XCTAssertEqual(healthToggle.value as? String, "0",
                       "Apple Health opt-in must start OFF by default")
        XCTAssertEqual(weeklySummaryToggle.value as? String, "0",
                       "Weekly Summary opt-in must start OFF by default")

        // Toggle ONLY the Weekly Summary switch on. Tap the trailing edge: a
        // centre `.tap()` on this full-width labelled Toggle can land off the
        // interactive area and miss (same workaround as OnboardingHealthStepUITests).
        weeklySummaryToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        let isOn = NSPredicate(format: "value == '1'")
        let exp = XCTNSPredicateExpectation(predicate: isOn, object: weeklySummaryToggle)
        let result = XCTWaiter().wait(for: [exp], timeout: 5)
        XCTAssertEqual(result, .completed,
                       "Weekly Summary toggle should read on after tapping")

        // D-06 independence: the Health toggle must still be off.
        XCTAssertEqual(healthToggle.value as? String, "0",
                       "Apple Health toggle must remain OFF when only Weekly Summary is toggled on")

        // Finish onboarding via "Done" → lands on the main shell (Home tab).
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5),
                      "Apple Health step 'Done' button should appear")
        done.tap()

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Main shell (Home tab) should appear after finishing onboarding")

        // ENGG-02: the on-state is reflected in Settings immediately, no
        // separate action needed.
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5),
                      "Settings tab should be accessible after onboarding")
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Settings navigation bar should appear")
        app.swipeUp()

        var settingsToggle = app.switches["Weekly check-in"]
        if !settingsToggle.waitForExistence(timeout: 5) {
            app.swipeUp()
            settingsToggle = app.switches["Weekly check-in"]
        }
        XCTAssertTrue(settingsToggle.waitForExistence(timeout: 5),
                      "Weekly check-in toggle should be present in Settings")
        XCTAssertEqual(settingsToggle.value as? String, "1",
                       "Settings' Weekly check-in toggle should already read on, with no extra tap")
    }
}
