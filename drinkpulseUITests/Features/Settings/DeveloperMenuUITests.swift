import XCTest

/// Debug-only Developer menu (plan 0052). A replayed onboarding is a rehearsal: Done must not
/// write a profile (D0052-1), and the app returns to Home for the entrance (D0052-3).
@MainActor
final class DeveloperMenuUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_replayOnboarding_rehearsal_keepsSeededProfile() throws {
        let app = XCUIApplication()
        // The seeded profile is Male (UITestSeed.seedFixtures).
        app.launchArguments += ["-dp_onboarding_done", "YES", "-dp_uitest", "YES"]
        app.launch()

        openSettings(in: app)
        // The Developer section is the last Form section; its rows load once scrolled to.
        let replay = app.buttons["dp_dev_replay_onboarding"]
        for _ in 0..<6 where !replay.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(replay.waitForExistence(timeout: 5), "Developer 'Replay Onboarding' should be shown")
        replay.tap()

        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 5),
                      "Replay should open onboarding at Welcome")
        OnboardingWalk.walkToHealth(in: app, sex: "Female")
        app.buttons["Done"].tap()

        // The Home tab is labelled "Today" (`tab.home`).
        let homeTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5), "Tab bar should return after Done")
        XCTAssertTrue(homeTab.isSelected, "Rehearsal should end on Today for the entrance")

        openSettings(in: app)
        // Settings keeps its scroll position (still at Developer); the sex picker is at the top.
        let sexPicker = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Female' OR label CONTAINS 'Male'")
        ).firstMatch
        for _ in 0..<6 where !sexPicker.isHittable {
            app.swipeDown()
        }
        XCTAssertTrue(sexPicker.waitForExistence(timeout: 5), "Sex picker should be visible in Settings")
        XCTAssertFalse(sexPicker.label.contains("Female"),
                       "Rehearsal must not save its choices; picker label was '\(sexPicker.label)'")
    }

    private func openSettings(in app: XCUIApplication) {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10), "Settings tab should be shown")
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Settings navigation bar should appear")
    }
}
