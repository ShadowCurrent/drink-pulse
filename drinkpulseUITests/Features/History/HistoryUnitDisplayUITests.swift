import XCTest

@MainActor
final class HistoryUnitDisplayUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        app.launch()
    }

    func test_unitSwitch_reRendersSubtitle() throws {
        launchApp()
        openHistoryTab()
        let mlButton = eventButton(containing: "500 ml")
        XCTAssertTrue(mlButton.waitForExistence(timeout: 10),
                      "Metric mode: EventRow should show '500 ml'")

        switchVolumeUnit(to: "US fl oz")

        openHistoryTab()
        let flOzButton = eventButton(containing: "fl oz")
        XCTAssertTrue(flOzButton.waitForExistence(timeout: 5),
                      "US mode: EventRow should show 'fl oz'")
        XCTAssertFalse(eventButton(containing: "500 ml").waitForExistence(timeout: 2),
                       "US mode: '500 ml' text must not appear in the row")

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

    private func switchVolumeUnit(to label: String) {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10),
                      "Settings tab should be accessible")
        settingsTab.tap()

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
