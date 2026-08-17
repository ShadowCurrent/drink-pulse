import XCTest

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
        openGuidelineSheet()

        let who = row(RowID.who)
        XCTAssertTrue(who.waitForExistence(timeout: 5),
                      "WHO row should be present in the guideline sheet")
        XCTAssertTrue(who.isSelected,
                      "The current guideline (WHO) must expose the .isSelected trait")

        let germany = row(RowID.de)
        XCTAssertTrue(germany.waitForExistence(timeout: 5),
                      "Germany row should be present in the guideline sheet")
        XCTAssertFalse(germany.isSelected,
                       "A guideline that is not the current choice must not be marked selected")
    }

    func test_guidelinePicker_selectionTraitFollowsChoice() throws {
        launchApp()
        openSettings()
        openGuidelineSheet()

        let germany = row(RowID.de)
        XCTAssertTrue(germany.waitForExistence(timeout: 5),
                      "Germany row should be present in the guideline sheet")
        germany.tap()

        XCTAssertTrue(app.buttons["Germany (DHS)"].waitForExistence(timeout: 5),
                      "Settings row should reflect the new choice after the sheet dismisses")
        openGuidelineSheet()

        let germanyAgain = row(RowID.de)
        XCTAssertTrue(germanyAgain.waitForExistence(timeout: 5),
                      "Germany row should be present after reopening the sheet")
        XCTAssertTrue(germanyAgain.isSelected,
                      "The newly chosen guideline must expose the .isSelected trait")
        XCTAssertFalse(row(RowID.who).isSelected,
                       "The previously chosen guideline must no longer be marked selected")
    }

    func test_guidelinePicker_rendersEveryChoiceAsCardRow_andSelectionStillWorks() throws {
        launchApp()
        openSettings()
        openGuidelineSheet()

        for identifier in RowID.all {
            let element = row(identifier)
            XCTAssertTrue(element.waitForExistence(timeout: 5),
                          "Guideline '\(identifier)' should render as a card row after the conversion")
        }

        for identifier in [RowID.who, RowID.de] {
            let element = row(identifier)
            XCTAssertTrue(element.isHittable,
                          "Guideline row '\(identifier)' should be hittable inside the glass card")
            XCTAssertGreaterThanOrEqual(element.frame.height, 44,
                                        "Guideline row '\(identifier)' must meet the 44pt minimum hit target")
        }

        row(RowID.de).tap()
        XCTAssertFalse(app.navigationBars["Guideline"].waitForExistence(timeout: 3),
                       "Selecting a guideline should dismiss the picker sheet")
        XCTAssertTrue(app.buttons["Germany (DHS)"].waitForExistence(timeout: 5),
                      "Settings guideline row should read the newly chosen guideline")
    }

    // MARK: - Helpers

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

    private func openGuidelineSheet() {
        let guidelineRow = app.buttons
            .matching(NSPredicate(format: "label CONTAINS 'Global' OR label CONTAINS 'DHS'"))
            .firstMatch
        XCTAssertTrue(guidelineRow.waitForExistence(timeout: 5),
                      "Settings guideline row should be tappable")
        guidelineRow.tap()
        XCTAssertTrue(app.navigationBars["Guideline"].waitForExistence(timeout: 5),
                      "Guideline picker sheet should present")
    }

    private func row(_ identifier: String) -> XCUIElement {
        app.buttons[identifier].firstMatch
    }
}

private enum RowID {
    static let who = "guidelineChoiceRow.who"
    static let de = "guidelineChoiceRow.de"
    static let uk = "guidelineChoiceRow.uk"
    static let us = "guidelineChoiceRow.us"
    static let au = "guidelineChoiceRow.au"
    static let ca = "guidelineChoiceRow.ca"

    static let all = [who, de, uk, us, au, ca]
}
