import XCTest

@MainActor
final class SettingsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(unit: String = "metric") {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", unit,
        ]
        app.launch()
    }

    // MARK: - Appearance mode

    func test_appearanceMode_reflectsSelectedOption() throws {
        launchApp()
        openSettings()

        let modeButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Appearance, '")
        ).firstMatch
        XCTAssertTrue(modeButton.waitForExistence(timeout: 5),
                      "Appearance mode picker button should be visible")
        let startLabel = modeButton.label
        let target = startLabel.contains("Dark") ? "Light" : "Dark"

        modeButton.tap()
        let option = app.buttons[target]
        XCTAssertTrue(option.waitForExistence(timeout: 3),
                      "'\(target)' option should appear in the appearance-mode menu")
        option.tap()

        let updated = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Appearance, '")
        ).firstMatch
        XCTAssertTrue(updated.waitForExistence(timeout: 3),
                      "Appearance mode picker should remain addressable")
        XCTAssertTrue(updated.label.contains(target),
                      "Appearance mode picker should now read \(target), got '\(updated.label)'")
    }

    // MARK: - Guideline picker

    func test_guidelinePicker_changePersists() throws {
        launchApp()
        openSettings()

        let whoRow = app.buttons["WHO (Global)"]
        XCTAssertTrue(whoRow.waitForExistence(timeout: 5),
                      "Guideline row should start on 'WHO (Global)'")
        whoRow.tap()

        let germany = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Germany (DHS)'")
        ).firstMatch
        XCTAssertTrue(germany.waitForExistence(timeout: 5),
                      "Germany (DHS) option should appear in the guideline sheet")
        germany.tap()

        let germanyRow = app.buttons["Germany (DHS)"]
        XCTAssertTrue(germanyRow.waitForExistence(timeout: 5),
                      "Guideline row should update to 'Germany (DHS)' after selection")

        app.tabBars.buttons["History"].tap()
        openSettings()
        XCTAssertTrue(app.buttons["Germany (DHS)"].waitForExistence(timeout: 5),
                      "Guideline choice should persist across a tab round-trip")
        XCTAssertFalse(app.buttons["WHO (Global)"].exists,
                       "Old WHO choice must not reappear after switching")
    }

    // MARK: - Unit-system switch reflected in volumes

    func test_unitSwitch_reflectsInDisplayedVolumes() throws {
        launchApp(unit: "metric")

        openHistory()
        XCTAssertTrue(eventRow(containing: "500 ml").waitForExistence(timeout: 10),
                      "Metric mode: History should show the seeded '500 ml' beer")

        openSettings()
        let volumeUnitButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Millilitres' OR label CONTAINS 'fl oz'")
        ).firstMatch
        XCTAssertTrue(volumeUnitButton.waitForExistence(timeout: 5),
                      "Volume unit picker button should be visible in Settings")
        volumeUnitButton.tap()
        let usOption = app.buttons["US fl oz"]
        XCTAssertTrue(usOption.waitForExistence(timeout: 3),
                      "'US fl oz' option should appear in the volume-unit menu")
        usOption.tap()

        openHistory()
        XCTAssertTrue(eventRow(containing: "fl oz").waitForExistence(timeout: 5),
                      "US mode: History should render the volume in 'fl oz'")
        XCTAssertFalse(eventRow(containing: "500 ml").waitForExistence(timeout: 2),
                       "US mode: '500 ml' must not appear once the unit switched")
    }

    // MARK: - App Lock & Data section

    func test_appLockRow_isPresentAndAddressable() throws {
        launchApp()
        openSettings()

        let appLock = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'App Lock'")
        ).firstMatch
        XCTAssertTrue(appLock.waitForExistence(timeout: 5),
                      "App Lock row should be present in the Privacy section")
        var attempts = 0
        while !appLock.isHittable && attempts < 6 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(appLock.isHittable,
                      "App Lock row should be addressable (hittable)")
    }

    func test_dataSection_isVisible() throws {
        launchApp()
        openSettings()

        let exportRow = app.buttons["Export all data"]
        if !exportRow.waitForExistence(timeout: 5) {
            app.swipeUp()
        }
        XCTAssertTrue(exportRow.waitForExistence(timeout: 5),
                      "Data section (Export row) should be visible in Settings")
    }

    // MARK: - Helpers

    private func openSettings() {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10),
                      "Settings tab should be accessible after launch")
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Settings navigation bar should appear")
    }

    private func openHistory() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10),
                      "History tab should be accessible")
        tab.tap()
    }

    private func eventRow(containing substring: String) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", substring)
        ).firstMatch
    }
}
