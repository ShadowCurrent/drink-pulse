import XCTest

/// UI tests for Settings → Apple Health (plan-0036, W4): the opt-in write-back
/// toggle and the first-enable backfill dialog.
///
/// Under `-dp_uitest`, `HealthService` uses a non-prompting stub store
/// (`UITestHealthStore`) that auto-grants authorization, so enabling Health does
/// **not** raise the real system permission sheet and touches no device Health
/// store. The tests drive the *real* toggle and assert the user-visible wiring:
/// the switch reflects ON after a granted enable, and the backfill confirmation
/// dialog appears on first enable when seeded history exists.
///
/// Locale independence: every element is keyed off the app's own English text
/// (the app is English-only) or the switch value, never a system-process
/// control. The simulator's system locale (Polish) does not affect app strings.
@MainActor
final class HealthSettingsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        // -dp_uitest seeds a deterministic 500 ml beer event, so first enable has
        // history and must offer backfill.
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
        ]
        app.launch()
    }

    /// Toggling Health on (stub auto-grants) flips the switch to on and, because
    /// seeded history exists, presents the backfill confirmation dialog. Pins the
    /// enable → on-state + first-enable-backfill wiring end to end.
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

        // Enable → stub auto-grants; first enable with seeded history offers backfill.
        toggle.tap()

        let addPast = app.buttons["Add past drinks"]
        XCTAssertTrue(addPast.waitForExistence(timeout: 5),
                      "Backfill dialog should appear on first enable when history exists")

        // Accept backfill to dismiss the dialog (the UI-test stub records the
        // writes in memory — no real Health store is touched).
        addPast.tap()

        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "1",
                       "Apple Health toggle should be on after a granted enable")
    }

    /// The Apple Health section's inline hint copy is visible, anchoring the
    /// section as addressable regardless of toggle state.
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
        // Apple Health sits below the fold (under Reminders); nudge it into view.
        app.swipeUp()
        app.swipeUp()
    }
}
