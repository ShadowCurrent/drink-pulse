import XCTest

/// Shared launch/locator/polling helpers for `InsightsUITests`, split out to
/// keep the main test file under the project's 300-line ceiling.
extension InsightsUITests {

    /// Builds and launches the app straight into the shell with the multi-day
    /// Insights seed. Kept off the nonisolated `setUpWithError` override so the
    /// MainActor-isolated XCUI calls run on the MainActor.
    func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_dataset", "multiday",
        ]
        app.launch()
    }

    /// Opens the Insights tab and waits for its navigation bar.
    func openInsights() {
        let insightsTab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 10),
                      "Insights tab button should be visible after launch")
        insightsTab.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5),
                      "Insights screen navigation bar should appear")
    }

    /// Reads the current hero "Total" value. The value text is the 40-pt rounded
    /// number+unit (e.g. "2.0 std"); it surfaces as a static text containing the
    /// "std" unit token under the hero card. Returns "" if not yet rendered.
    func heroTotalLabel() -> String {
        let candidate = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "std")
        ).firstMatch
        return candidate.exists ? candidate.label : ""
    }

    /// First element (any type) whose accessibility label equals `label`.
    func firstElement(withLabel label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", label)
        ).firstMatch
    }

    /// First element (any type) whose accessibility label begins with `prefix`.
    func firstElement(beginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch
    }

    /// First element (any type) whose accessibility label contains `needle`.
    func firstElement(containing needle: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", needle)
        ).firstMatch
    }

    /// Polls `condition` until it returns true or `timeout` elapses.
    func waitUntil(timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            usleep(150_000)
        }
        return condition()
    }

    /// Fired by the `Timer` scheduled in
    /// `test_scrubbingAreaChart_updatesHeroTotal_andRevertsOnRelease()`,
    /// mid-hold. Target-action (not a Swift closure) sidesteps the `@Sendable`
    /// capture-checking a closure-based timer would trigger for a
    /// MainActor-isolated `XCTestCase`; `RunLoop.main.add` guarantees this
    /// fires on the main thread, the same thread the blocking `press(...)`
    /// call services via its internal run-loop wait.
    @objc func sampleHeroTotalDuringHold(_ timer: Timer) {
        sampledDuringHold = heroTotalLabel()
    }
}
