import XCTest

@MainActor
final class HealthSettingsUITests: XCTestCase {
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

    func test_healthToggle_turnsOn_andOffersBackfill() throws {
        launchApp()
        openSettings()

        let toggle = app.switches["Write to Apple Health"]
        if !toggle.waitForExistence(timeout: 5) {
            app.swipeUp()
        }
        XCTAssertTrue(toggle.waitForExistence(timeout: 5),
                      "Apple Health toggle should be present in Settings")
        XCTAssertEqual(toggle.value as? String, "0",
                       "Apple Health toggle should start off")

        toggle.tap()

        let addPast = app.buttons["Add past drinks"]
        XCTAssertTrue(addPast.waitForExistence(timeout: 5),
                      "Backfill dialog should appear on first enable when history exists")

        addPast.tap()

        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "1",
                       "Apple Health toggle should be on after a granted enable")
    }

    func test_healthSection_showsHintCopy() throws {
        launchApp()
        openSettings()

        let hint = app.staticTexts["Mirror your logged drinks to Apple Health."]
        if !hint.waitForExistence(timeout: 5) {
            app.swipeUp()
        }
        XCTAssertTrue(hint.waitForExistence(timeout: 5),
                      "Apple Health section hint copy should be visible in Settings")
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
        app.swipeUp()
    }
}
