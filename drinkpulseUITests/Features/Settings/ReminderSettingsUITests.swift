import XCTest

@MainActor
final class ReminderSettingsUITests: XCTestCase {
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

    func test_reminderToggle_revealsAndHidesTimeRow() throws {
        launchApp()
        openSettings()

        let toggle = app.switches["Daily log reminder"]
        if !toggle.waitForExistence(timeout: 5) {
            app.swipeUp()
        }
        XCTAssertTrue(toggle.waitForExistence(timeout: 5),
                      "Reminders toggle should be present in Settings")

        XCTAssertFalse(app.staticTexts["Time"].exists,
                       "Time row should be hidden when the reminder is off")

        toggle.tap()
        XCTAssertTrue(app.staticTexts["Time"].waitForExistence(timeout: 5),
                      "Time row should appear once the reminder is enabled")

        toggle.tap()
        XCTAssertFalse(app.staticTexts["Time"].waitForExistence(timeout: 2),
                       "Time row should disappear once the reminder is turned off")
    }

    func test_reminderSection_showsHintCopy() throws {
        launchApp()
        openSettings()

        let hint = app.staticTexts["A daily nudge to log what you drank."]
        if !hint.waitForExistence(timeout: 5) {
            app.swipeUp()
        }
        XCTAssertTrue(hint.waitForExistence(timeout: 5),
                      "Reminders section hint copy should be visible in Settings")
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
