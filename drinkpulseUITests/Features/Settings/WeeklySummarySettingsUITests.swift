import XCTest

@MainActor
final class WeeklySummarySettingsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
        ]
        app.launch()
    }

    func test_weeklySummaryToggle_startsOff_thenTogglesOn() throws {
        launchApp()
        openSettings()

        var toggle = app.switches["Weekly check-in"]
        if !toggle.waitForExistence(timeout: 5) {
            app.swipeUp()
            toggle = app.switches["Weekly check-in"]
        }
        XCTAssertTrue(toggle.waitForExistence(timeout: 5),
                      "Weekly check-in toggle should be present in Settings")
        XCTAssertEqual(toggle.value as? String, "0",
                       "Weekly check-in toggle must start OFF by default")

        toggle.tap()
        let isOn = NSPredicate(format: "value == '1'")
        let exp = XCTNSPredicateExpectation(predicate: isOn, object: toggle)
        let result = XCTWaiter().wait(for: [exp], timeout: 5)
        XCTAssertEqual(result, .completed,
                       "Weekly check-in toggle should read on after tapping")
    }

    func test_weeklySummarySection_showsHintCopy() throws {
        launchApp()
        openSettings()

        let hint = app.staticTexts["A weekly note on how this week compares to last."]
        if !hint.waitForExistence(timeout: 5) {
            app.swipeUp()
        }
        XCTAssertTrue(hint.waitForExistence(timeout: 5),
                      "Weekly Summary section hint copy should be visible in Settings")
    }

    // MARK: - Helpers

    private func openSettings() {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10),
                      "Settings tab should be accessible after launch")
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Settings navigation bar should appear")
        app.swipeUp()
    }
}
