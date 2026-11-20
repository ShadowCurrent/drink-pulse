import XCTest

/// Guideline as a system `Picker` with `.navigationLink` style (plan 0043 D0043-3): the row on
/// Settings pushes the option list; choosing an option pops back and persists.
@MainActor
final class GuidelinePickerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Tests

    func test_guidelinePicker_marksCurrentChoiceSelected() throws {
        launchApp()
        openSettings()
        openGuidelinePicker()

        let who = option("WHO (Global)")
        XCTAssertTrue(who.waitForExistence(timeout: 5), "WHO option should be listed")
        XCTAssertTrue(who.isSelected,
                      "The current guideline (WHO) must expose the .isSelected trait")

        let germany = option("Germany (DHS)")
        XCTAssertTrue(germany.waitForExistence(timeout: 5), "Germany option should be listed")
        XCTAssertFalse(germany.isSelected,
                       "A guideline that is not the current choice must not be marked selected")
    }

    func test_guidelinePicker_selectingPopsBack_andPersists() throws {
        launchApp()
        openSettings()
        openGuidelinePicker()

        let germany = option("Germany (DHS)")
        XCTAssertTrue(germany.waitForExistence(timeout: 5), "Germany option should be listed")
        germany.tap()

        XCTAssertTrue(app.navigationBars["Guideline"].waitForNonExistence(timeout: 5),
                      "Choosing an option should pop back to Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Settings should be on screen after the pop")
        XCTAssertTrue(guidelineRowText().contains("Germany (DHS)"),
                      "Guideline row should show the new choice, got '\(guidelineRowText())'")

        app.tabBars.buttons["History"].tap()
        openSettings()
        XCTAssertTrue(guidelineRowText().contains("Germany (DHS)"),
                      "Guideline choice should persist across a tab round-trip")

        openGuidelinePicker()
        XCTAssertTrue(option("Germany (DHS)").waitForExistence(timeout: 5))
        XCTAssertTrue(option("Germany (DHS)").isSelected,
                      "The newly chosen guideline must expose the .isSelected trait")
        XCTAssertFalse(option("WHO (Global)").isSelected,
                       "The previously chosen guideline must no longer be marked selected")
    }

    func test_guidelinePicker_optionsShowThresholdSummary() throws {
        launchApp()
        openSettings()
        openGuidelinePicker()

        for name in Self.selectableNames {
            let element = option(name)
            XCTAssertTrue(element.waitForExistence(timeout: 5), "'\(name)' option should be listed")
            XCTAssertTrue(element.label.contains("g/week"),
                          "'\(name)' option should show its threshold summary, got '\(element.label)'")
        }
    }

    // MARK: - Helpers

    private static let selectableNames = [
        "WHO (Global)", "Germany (DHS)", "UK (NHS)", "US (NIAAA)", "Australia (NHMRC)", "Canada (Health Canada)",
    ]

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
        ]
        app.launch()
    }

    private func openSettings() {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10),
                      "Settings tab should be accessible after launch")
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Settings navigation bar should appear")
    }

    private var guidelineRow: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Guideline'")).firstMatch
    }

    /// Label and value together: the picker row may expose the choice in either.
    private func guidelineRowText() -> String {
        let row = guidelineRow
        _ = row.waitForExistence(timeout: 5)
        return "\(row.label) \(row.value as? String ?? "")"
    }

    private func openGuidelinePicker() {
        XCTAssertTrue(guidelineRow.waitForExistence(timeout: 5),
                      "Settings guideline row should be tappable")
        guidelineRow.tap()
        XCTAssertTrue(app.navigationBars["Guideline"].waitForExistence(timeout: 5),
                      "Guideline option list should be pushed")
    }

    private func option(_ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
    }
}
