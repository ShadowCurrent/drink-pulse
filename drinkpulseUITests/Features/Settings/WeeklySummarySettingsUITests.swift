import XCTest

/// UI tests for Settings → Weekly check-in (phase-01, v1.1): the opt-in
/// weekly summary notification toggle and its hint copy.
///
/// Under `-dp_uitest`, the weekly-summary authorization request is expected to
/// auto-grant (mirroring the reminder/health stubs), so the tests drive the
/// *real* toggle and assert the user-visible wiring: the toggle starts off and
/// flips to on when tapped.
///
/// Locale independence: every element is keyed off the app's own English text
/// (the app is English-only), never a system-process control. The simulator's
/// system locale is Polish, which does not affect app-rendered strings.
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

    /// The Weekly Summary toggle starts off (a prior UI-test run that left the
    /// toggle on must never leak into this run's baseline), and tapping it
    /// flips it on.
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

    /// The Weekly Summary section's inline hint copy is visible, anchoring the
    /// section as addressable.
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
        // Weekly Summary sits below the fold on smaller screens; nudge it into view.
        app.swipeUp()
    }
}
