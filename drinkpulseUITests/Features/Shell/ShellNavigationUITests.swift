import XCTest

@MainActor
final class ShellNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    private let tabNames = ["Home", "Insights", "History", "Settings"]

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

        let homeTab = app.tabBars.buttons["Home"]
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

    // MARK: - Add Drink button present on every tab

    func test_addDrinkButton_presentOnEveryTab_opensSheet() throws {
        launchApp()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10),
                      "Tab bar should be visible after launch")

        for name in tabNames {
            app.tabBars.buttons[name].tap()
            XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5),
                          "\(name) screen should be shown before opening Add Drink")

            let addButton = app.buttons["Add Drink"]
            XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                          "Add Drink button should be present on the \(name) tab")
            addButton.tap()

            let addNavBar = app.navigationBars["Add Drink"]
            XCTAssertTrue(addNavBar.waitForExistence(timeout: 5),
                          "Tapping Add Drink on the \(name) tab should present "
                          + "the Add Drink sheet")

            dismissAddDrinkSheet()
        }
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

    // MARK: - VoiceOver dismissal semantics

    func test_voiceOver_cancelDismissesAddDrinkAndReturnsToHistory() throws {
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

        let cancel = app.navigationBars["Add Drink"].buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5),
                      "Cancel must remain a semantic element before VoiceOver interaction")

        try voiceOver.enable()
        defer { try? voiceOver.disable() }

        var utterances = [try voiceOver.currentSpeech().utterance]
        for _ in 0..<40 {
            utterances.append(try voiceOver.moveForward().utterance)
            if utterances.contains(where: { $0.localizedCaseInsensitiveContains("Cancel") }) { break }
        }
        XCTAssertTrue(utterances.contains(where: { $0.localizedCaseInsensitiveContains("Cancel") }),
                      "VoiceOver should announce the existing Cancel control; heard: \(utterances)")

        try voiceOver.disable()
        cancel.tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5),
                      "VoiceOver-tested dismissal should return to the originating History tab")
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
