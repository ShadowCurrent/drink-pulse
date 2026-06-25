import XCTest

/// Asserts that switching the Settings volume-unit picker between metric and
/// US causes the EventRow to re-render volumes in "ml" vs "fl oz" (plan-0030).
///
/// Accessibility structure note: the EventRow is a `.buttonStyle(.plain)`
/// Button inside a List cell; its combined accessibilityLabel is on the
/// Button, not the cell container.  Query via `app.buttons.matching(…)`.
@MainActor
final class HistoryUnitDisplayUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Builds and launches the app. Kept off the nonisolated `setUpWithError`
    /// override so the MainActor-isolated XCUI calls run on the MainActor.
    private func launchApp() {
        app = XCUIApplication()
        // Start in metric so we can switch to US and back.
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        app.launch()
    }

    /// Switches metric → US → metric and asserts the EventRow's label
    /// changes between "ml" and "fl oz" at each step.
    func test_unitSwitch_reRendersSubtitle() throws {
        launchApp()
        // Step 1: verify initial metric display.
        openHistoryTab()
        let mlButton = eventButton(containing: "500 ml")
        XCTAssertTrue(mlButton.waitForExistence(timeout: 10),
                      "Metric mode: EventRow should show '500 ml'")

        // Step 2: switch to US fl oz via Settings.
        switchVolumeUnit(to: "US fl oz")

        // Step 3: return to History and assert fl oz.
        openHistoryTab()
        let flOzButton = eventButton(containing: "fl oz")
        XCTAssertTrue(flOzButton.waitForExistence(timeout: 5),
                      "US mode: EventRow should show 'fl oz'")
        XCTAssertFalse(eventButton(containing: "500 ml").waitForExistence(timeout: 2),
                       "US mode: '500 ml' text must not appear in the row")

        // Step 4: switch back to metric.
        switchVolumeUnit(to: "Millilitres (ml)")
        openHistoryTab()
        let backToMl = eventButton(containing: "500 ml")
        XCTAssertTrue(backToMl.waitForExistence(timeout: 5),
                      "After switching back to metric, row should show '500 ml' again")
    }

    // MARK: - Helpers

    private func openHistoryTab() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10),
                      "History tab should be accessible")
        tab.tap()
    }

    private func eventButton(containing substring: String) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", substring)
        ).firstMatch
    }

    /// Opens Settings and selects the given volume-unit picker option.
    private func switchVolumeUnit(to label: String) {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10),
                      "Settings tab should be accessible")
        settingsTab.tap()

        // The Volume unit Picker (.pickerStyle(.menu)) surfaces as a Button
        // whose label reflects the current selection.
        let volumeUnitButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Millilitres' OR label CONTAINS 'fl oz'")
        ).firstMatch
        XCTAssertTrue(volumeUnitButton.waitForExistence(timeout: 5),
                      "Volume unit picker button should be visible in Settings")
        volumeUnitButton.tap()

        let option = app.buttons[label]
        XCTAssertTrue(option.waitForExistence(timeout: 3),
                      "Option '\(label)' should appear in the picker menu")
        option.tap()
    }
}
