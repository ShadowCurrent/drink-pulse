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

    // MARK: - Form container (plan 0043)

    func test_settings_showsLargeTitle_andNoGlassScrollView() throws {
        launchApp()
        openSettings()

        XCTAssertTrue(app.navigationBars["Settings"].exists,
                      "Settings navigation bar should carry the 'Settings' title")
        XCTAssertTrue(app.collectionViews.firstMatch.waitForExistence(timeout: 5),
                      "Settings should be a Form (collection view), not a glass ScrollView")
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

        let guidelineRow = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Guideline'")
        ).firstMatch
        XCTAssertTrue(guidelineRow.waitForExistence(timeout: 5),
                      "Guideline picker row should be on Settings")
        guidelineRow.tap()

        let germany = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Germany (DHS)'")
        ).firstMatch
        XCTAssertTrue(germany.waitForExistence(timeout: 5),
                      "Germany (DHS) option should appear in the pushed guideline list")
        germany.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Choosing an option should pop back to Settings")

        app.tabBars.buttons["History"].tap()
        openSettings()
        let row = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Guideline'")
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let text = "\(row.label) \(row.value as? String ?? "")"
        XCTAssertTrue(text.contains("Germany (DHS)"),
                      "Guideline choice should persist across a tab round-trip, got '\(text)'")
        XCTAssertFalse(text.contains("WHO (Global)"),
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

        let appLock = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH 'App Lock'")
        ).firstMatch
        // A Form loads rows lazily: scroll until the Privacy row is in the hierarchy.
        var swipes = 0
        while !appLock.waitForExistence(timeout: 1) && swipes < 8 {
            app.collectionViews.firstMatch.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(appLock.exists,
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

    // MARK: - Notifications section (plan 0043 D0043-1)

    func test_notifications_showsBothTogglesInOneSection() throws {
        launchApp()
        openSettings()

        let header = app.staticTexts["Notifications"]
        scrollUntilExists(header)
        XCTAssertTrue(header.exists, "Settings should show a 'Notifications' section header")
        XCTAssertFalse(app.staticTexts["Reminders"].exists,
                       "The separate 'Reminders' section header should be gone")

        let reminder = app.switches["Daily log reminder"]
        let weekly = app.switches["Weekly check-in"]
        scrollUntilExists(weekly)
        XCTAssertTrue(reminder.exists, "Daily log reminder switch should be in Notifications")
        XCTAssertTrue(weekly.exists, "Weekly check-in switch should be in Notifications")

        let reminderHint = app.staticTexts["A daily nudge to log what you drank."]
        let weeklyHint = app.staticTexts["A weekly note on how this week compares to last."]
        scrollUntilExists(weeklyHint)
        XCTAssertTrue(reminderHint.exists, "Reminder hint should show in the section footer")
        XCTAssertTrue(weeklyHint.exists, "Weekly summary hint should show in the section footer")
    }

    // MARK: - Delete all (plan 0043 review focus 2)

    func test_deleteAll_cancel_keepsData() throws {
        launchApp()
        openSettings()

        let delete = app.buttons["Delete all data"]
        scrollUntilExists(delete)
        var swipes = 0
        while !delete.isHittable && swipes < 4 {
            app.collectionViews.firstMatch.swipeUp()
            swipes += 1
        }
        delete.tap()

        let alert = app.alerts["Delete All Data?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Delete-all confirmation should appear")
        XCTAssertEqual(app.alerts.count, 1, "Exactly one confirmation alert should be presented")
        alert.buttons["Cancel"].tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 5), "Cancel should dismiss the alert")

        openHistory()
        XCTAssertTrue(eventRow(containing: "500 ml").waitForExistence(timeout: 10),
                      "Cancelling delete-all must keep the seeded '500 ml' event")
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

    /// A Form loads rows lazily: swipe the collection view until the element is in the hierarchy.
    private func scrollUntilExists(_ element: XCUIElement, maxSwipes: Int = 8) {
        var swipes = 0
        while !element.waitForExistence(timeout: 1) && swipes < maxSwipes {
            app.collectionViews.firstMatch.swipeUp()
            swipes += 1
        }
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
