import XCTest

@MainActor
final class OnboardingHealthStepUITests: XCTestCase {

    func test_healthStep_togglesOn_thenFinishes() throws {
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
        XCTAssertTrue(healthToggle.waitForExistence(timeout: 5),
                      "Apple Health step toggle should appear as the 4th step")
        XCTAssertEqual(healthToggle.value as? String, "0",
                       "Apple Health opt-in must start OFF by default")

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

        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5),
                      "Apple Health step 'Done' button should appear")
        done.tap()

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Main shell (Home tab) should appear after finishing onboarding")
    }
}
