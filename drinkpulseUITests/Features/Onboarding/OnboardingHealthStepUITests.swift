import XCTest

/// W8 (plan-0036): the Apple Health opt-in is a new optional 4th onboarding
/// step, **off by default**. This walks Welcome → Profile → Guideline → Apple
/// Health, asserts the Health toggle starts off, toggles it on (the
/// `-dp_uitest` `UITestHealthStore` stub auto-grants, so no real system
/// permission sheet appears), confirms the switch reflects on, then finishes
/// and lands on the main shell.
///
/// Locale-independent: assertions key off the app's English labels (English-
/// only by product rule) and the Switch's numeric value ("0"/"1"), never on
/// system-process UI or localized system labels.
///
/// Launch hooks:
///   - `-dp_uitest YES`           → in-memory store + non-prompting Health stub.
///   - `-dp_force_onboarding YES`  → always show OnboardingView, skip seeding.
@MainActor
final class OnboardingHealthStepUITests: XCTestCase {

    /// The 4th step appears, the toggle starts off, toggling drives it on, and
    /// finishing lands on Home.
    func test_healthStep_togglesOn_thenFinishes() throws {
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

        // Guideline → Apple Health.
        let guidelineContinue = app.buttons["Continue"]
        XCTAssertTrue(guidelineContinue.waitForExistence(timeout: 5),
                      "Guideline step 'Continue' should appear")
        guidelineContinue.tap()

        // Step 4: Apple Health — the toggle starts off (Switch value "0").
        let healthToggle = app.switches["Write to Apple Health"]
        XCTAssertTrue(healthToggle.waitForExistence(timeout: 5),
                      "Apple Health step toggle should appear as the 4th step")
        XCTAssertEqual(healthToggle.value as? String, "0",
                       "Apple Health opt-in must start OFF by default")

        // Toggle on — the stub auto-grants, so it stays on (Switch value "1").
        // Tap the switch control on the trailing edge: a centre `.tap()` on this
        // full-width labelled Toggle can land off the interactive area and miss.
        healthToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        let isOn = NSPredicate(format: "value == '1'")
        let exp = XCTNSPredicateExpectation(predicate: isOn, object: healthToggle)
        let result = XCTWaiter().wait(for: [exp], timeout: 5)
        if result != .completed {
            let denied = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS 'Apple Health access is off'")
            ).firstMatch
            XCTFail("DIAG value=\(String(describing: healthToggle.value)) deniedShown=\(denied.exists)")
            print(app.debugDescription)
        }

        // Finish onboarding via "Done" → lands on the main shell (Home tab).
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5),
                      "Apple Health step 'Done' button should appear")
        done.tap()

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Main shell (Home tab) should appear after finishing onboarding")
    }
}
