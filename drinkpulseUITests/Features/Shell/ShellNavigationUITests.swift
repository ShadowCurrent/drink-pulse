import XCTest

@MainActor
final class ShellNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    private let tabNames = [UITestTabs.today, "Insights", "History", "Settings"]

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

    // MARK: - Tabs reachable & switch content

    func test_allFourTabs_areReachable_andSwitchContent() throws {
        launchApp()

        let homeTab = app.tabBars.buttons[UITestTabs.today]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Home tab button should be visible after launch")

        for name in tabNames {
            let tabButton = app.tabBars.buttons[name]
            XCTAssertTrue(tabButton.waitForExistence(timeout: 5),
                          "\(name) tab button should exist in the tab bar")
            tabButton.tap()

            let screenNavBar = app.navigationBars[name]
            XCTAssertTrue(screenNavBar.waitForExistence(timeout: 5),
                          "Selecting the \(name) tab should show the \(name) "
                          + "screen's navigation bar")
        }
    }

    // MARK: - Add Drink is each logging screen's primary action (plan 0044 D0044-1)

    func test_addDrinkButton_presentOnLoggingTabs_opensSheet() throws {
        launchApp()

        XCTAssertTrue(app.tabBars.buttons[UITestTabs.today].waitForExistence(timeout: 10),
                      "Tab bar should be visible after launch")

        for name in [UITestTabs.today, "Insights", "History"] {
            app.tabBars.buttons[name].tap()
            let screenBar = app.navigationBars[name]
            XCTAssertTrue(screenBar.waitForExistence(timeout: 5),
                          "\(name) screen should be shown before opening Add Drink")

            let addButton = screenBar.buttons["addDrink.button"]
            XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                          "Add Drink should sit in the \(name) navigation bar")
            XCTAssertEqual(addButton.label, "Add Drink",
                           "Add Drink keeps its accessibility label on the \(name) tab")
            addButton.tap()

            let addNavBar = app.navigationBars["Add Drink"]
            XCTAssertTrue(addNavBar.waitForExistence(timeout: 5),
                          "Tapping Add Drink on the \(name) tab should present "
                          + "the Add Drink sheet")

            dismissAddDrinkSheet()
        }
    }

    func test_addDrinkButton_absentOnSettings() throws {
        launchApp()

        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10),
                      "Settings tab button should be visible after launch")
        settingsTab.tap()
        let settingsBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsBar.waitForExistence(timeout: 5),
                      "Settings screen should be shown")

        XCTAssertFalse(app.buttons["addDrink.button"].exists,
                       "Settings logs no drinks, so it has no Add Drink button")
        XCTAssertFalse(settingsBar.buttons["Add Drink"].exists,
                       "The Settings navigation bar carries no Add Drink button")
    }

    func test_loggingFromHomePlus_showsDrinkInHistory() throws {
        launchApp()

        let homeBar = app.navigationBars[UITestTabs.today]
        XCTAssertTrue(homeBar.waitForExistence(timeout: 10), "Home should be shown after launch")
        let addButton = homeBar.buttons["addDrink.button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Home should offer Add Drink")
        addButton.tap()

        let wineTile = app.buttons["Wine"]
        XCTAssertTrue(wineTile.waitForExistence(timeout: 10),
                      "The Add Drink grid should show the Wine preset")
        wineTile.tap()
        // History rows show the serving name, so a custom name identifies this drink.
        let customName = "Plus Logged Wine"
        let nameField = app.textFields["Custom Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5),
                      "The Wine detail screen should offer a Custom Name field")
        nameField.tap()
        nameField.typeText(customName)
        let saveButton = app.navigationBars["Wine"].buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5),
                      "The Wine detail screen should offer Save")
        saveButton.tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5),
                      "Saving should dismiss the Add Drink sheet")

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5),
                      "History screen should appear")
        let wineRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", customName)).firstMatch
        XCTAssertTrue(wineRow.waitForExistence(timeout: 10),
                      "The drink logged from the Home + should appear in History")
    }

    // MARK: - Sheet dismiss returns to prior tab

    func test_dismissingAddDrink_returnsToPriorTab() throws {
        launchApp()

        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 10),
                      "History tab button should be visible after launch")
        historyTab.tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5),
                      "History screen should be shown before opening Add Drink")

        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "Add Drink button should be present on the History tab")
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5),
                      "Add Drink sheet should be presented from the History tab")

        dismissAddDrinkSheet()

        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5),
                      "Dismissing Add Drink should return to the History tab")
        XCTAssertFalse(app.navigationBars["Add Drink"].exists,
                       "Add Drink sheet should be dismissed")
    }

    // MARK: - Cancel activation under a running VoiceOver service

    func test_withVoiceOverRunning_focusCancelThenActivate_dismissesAddDrinkToOriginatingHistoryTab() throws {
        let voiceOver = XCUIDevice.shared.voiceOverService
        if voiceOver.isEnabled {
            try voiceOver.disable()
        }
        launchApp()

        let history = app.tabBars.buttons["History"]
        XCTAssertTrue(history.waitForExistence(timeout: 10))
        history.tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))

        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].buttons["Cancel"].waitForExistence(timeout: 5),
                      "Cancel must remain a semantic element before VoiceOver interaction")

        addTeardownBlock { try? voiceOver.disable() }
        do {
            try voiceOver.enable()
        } catch XCUIVoiceOverService.Error.failedToStart {
            throw XCTSkip("VoiceOver service could not start: \(XCUIVoiceOverService.Error.failedToStart)")
        }

        var utterances = [try voiceOver.currentSpeech().utterance]
        for _ in 0..<40 {
            if utterances.contains(where: { $0.localizedCaseInsensitiveContains("Cancel") }) { break }
            utterances.append(try voiceOver.moveForward().utterance)
        }
        XCTAssertTrue(utterances.contains(where: { $0.localizedCaseInsensitiveContains("Cancel") }),
                      "VoiceOver focus should reach the Cancel control; heard: \(utterances)")

        let cancel = app.navigationBars["Add Drink"].buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        cancel.doubleTap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 10),
                      "Activating Cancel under VoiceOver should dismiss the Add Drink sheet")
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 10),
                      "Dismissal under VoiceOver should return to the originating History tab")
    }

    // MARK: - Helpers

    private func dismissAddDrinkSheet() {
        let cancelButton = app.navigationBars["Add Drink"].buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5),
                      "Add Drink sheet should have a Cancel button to dismiss it")
        cancelButton.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5),
                      "Add Drink sheet should be dismissed after tapping Cancel")
    }
}
