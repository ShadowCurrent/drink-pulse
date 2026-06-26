import XCTest

/// UI tests for Settings → Reminders (plan-0016): the opt-in daily log-reminder
/// toggle and its time row.
///
/// Under `-dp_uitest`, `ReminderService` uses a non-prompting stub centre
/// (`UITestNotificationCenter`) so enabling the reminder does **not** raise the
/// real, locale-dependent system permission alert and schedules nothing real.
/// The tests therefore drive the *real* toggle and assert the user-visible
/// wiring: the time row appears only when the reminder is on.
///
/// Locale independence: every element is keyed off the app's own English text
/// (the app is English-only), never a system-process control. The simulator's
/// system locale is Polish, which does not affect app-rendered strings.
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

    /// The Reminders toggle is present; turning it on reveals the Time row, and
    /// turning it off hides it again. Pins the toggle→time-row wiring end to end.
    func test_reminderToggle_revealsAndHidesTimeRow() throws {
        launchApp()
        openSettings()

        let toggle = app.switches["Daily log reminder"]
        if !toggle.waitForExistence(timeout: 5) {
            app.swipeUp()
        }
        XCTAssertTrue(toggle.waitForExistence(timeout: 5),
                      "Reminders toggle should be present in Settings")

        // Time row is hidden while the reminder is off.
        XCTAssertFalse(app.staticTexts["Time"].exists,
                       "Time row should be hidden when the reminder is off")

        // Enable → Time row appears (stub auto-grants, no system prompt).
        toggle.tap()
        XCTAssertTrue(app.staticTexts["Time"].waitForExistence(timeout: 5),
                      "Time row should appear once the reminder is enabled")

        // Disable → Time row disappears again.
        toggle.tap()
        XCTAssertFalse(app.staticTexts["Time"].waitForExistence(timeout: 2),
                       "Time row should disappear once the reminder is turned off")
    }

    /// The Reminders section's inline hint copy is visible regardless of state,
    /// anchoring the section as addressable.
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
        // Reminders sits below the fold on smaller screens; nudge it into view.
        app.swipeUp()
    }
}
