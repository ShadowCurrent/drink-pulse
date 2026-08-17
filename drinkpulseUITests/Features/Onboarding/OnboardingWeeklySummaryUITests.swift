import XCTest

@MainActor
final class OnboardingWeeklySummaryUITests: XCTestCase {

    func test_weeklySummaryToggle_independentOfHealthToggle_andReflectedInSettingsAfterDone() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_force_onboarding", "YES",
        ]
        app.launch()

        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 10),
                      "Welcome step should appear at launch")
        getStarted.tap()

        let profileContinue = app.buttons["Continue"]
        XCTAssertTrue(profileContinue.waitForExistence(timeout: 5),
                      "Profile step 'Continue' should appear")
        profileContinue.tap()

        let guidelineContinue = app.buttons["Continue"]
        XCTAssertTrue(guidelineContinue.waitForExistence(timeout: 5),
                      "Guideline step 'Continue' should appear")
        guidelineContinue.tap()

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

        weeklySummaryToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        let isOn = NSPredicate(format: "value == '1'")
        let exp = XCTNSPredicateExpectation(predicate: isOn, object: weeklySummaryToggle)
        let result = XCTWaiter().wait(for: [exp], timeout: 5)
        XCTAssertEqual(result, .completed,
                       "Weekly Summary toggle should read on after tapping")

        XCTAssertEqual(healthToggle.value as? String, "0",
                       "Apple Health toggle must remain OFF when only Weekly Summary is toggled on")

        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5),
                      "Apple Health step 'Done' button should appear")
        done.tap()

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Main shell (Home tab) should appear after finishing onboarding")

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
