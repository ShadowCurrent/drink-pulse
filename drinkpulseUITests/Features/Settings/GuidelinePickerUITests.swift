import XCTest

/// UI tests for the Settings guideline picker sheet, pinning finding **C14-4**.
///
/// Before this phase the Settings picker conveyed the current selection through a
/// checkmark glyph alone — no `.isSelected` accessibility trait, and the image was
/// neither labelled nor hidden — so a VoiceOver user heard the guideline name and
/// its threshold summary with no indication of which one was active. Its
/// near-identical onboarding sibling already carried the trait, which is exactly
/// the divergence finding A7-2 predicted from the duplicated row.
///
/// Both screens now render through the single `GuidelineChoiceRow`, so the trait
/// cannot regress on one screen while surviving on the other.
///
/// Rows are addressed by the `guidelineChoiceRow.<rawValue>` accessibility
/// identifier, never by localized label text: the simulator's system locale is
/// Polish, and identifiers keep these assertions independent of it.
///
/// A separate class from `SettingsUITests` rather than an extension, because that
/// suite owns its own `app` property and exercises a different surface.
@MainActor
final class GuidelinePickerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Tests

    /// The row for the profile's current guideline reports `.isSelected`; a
    /// different row does not. This assertion was impossible before the shared
    /// row existed — the selection was an unlabelled glyph.
    func test_guidelinePicker_marksCurrentChoiceSelected() throws {
        launchApp()
        openSettings()
        openGuidelineSheet()

        // The seeded profile is on WHO (UITestSeed.seedFixtures).
        let who = row(.who)
        XCTAssertTrue(who.waitForExistence(timeout: 5),
                      "WHO row should be present in the guideline sheet")
        XCTAssertTrue(who.isSelected,
                      "The current guideline (WHO) must expose the .isSelected trait")

        let germany = row(.de)
        XCTAssertTrue(germany.waitForExistence(timeout: 5),
                      "Germany row should be present in the guideline sheet")
        XCTAssertFalse(germany.isSelected,
                       "A guideline that is not the current choice must not be marked selected")
    }

    /// Choosing a different guideline moves the trait with it.
    func test_guidelinePicker_selectionTraitFollowsChoice() throws {
        launchApp()
        openSettings()
        openGuidelineSheet()

        let germany = row(.de)
        XCTAssertTrue(germany.waitForExistence(timeout: 5),
                      "Germany row should be present in the guideline sheet")
        germany.tap()

        // Selecting dismisses the sheet; reopen it to inspect the new state.
        XCTAssertTrue(app.buttons["Germany (DHS)"].waitForExistence(timeout: 5),
                      "Settings row should reflect the new choice after the sheet dismisses")
        openGuidelineSheet()

        let germanyAgain = row(.de)
        XCTAssertTrue(germanyAgain.waitForExistence(timeout: 5),
                      "Germany row should be present after reopening the sheet")
        XCTAssertTrue(germanyAgain.isSelected,
                      "The newly chosen guideline must expose the .isSelected trait")
        XCTAssertFalse(row(.who).isSelected,
                       "The previously chosen guideline must no longer be marked selected")
    }

    // MARK: - Helpers

    /// Launches with the deterministic seed (profile on WHO) and onboarding skipped.
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

    /// Taps the Settings guideline row to present the picker sheet. The row is a
    /// plain button labelled exactly the current choice's display name; the sheet
    /// is confirmed by its own "Guideline" navigation bar.
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

    /// A picker row addressed by its stable identifier rather than localized text.
    private func row(_ choice: String) -> XCUIElement {
        app.buttons["guidelineChoiceRow.\(choice)"].firstMatch
    }
}

/// Raw values of the guideline cases these tests address, kept as plain strings so
/// the UI-test target does not need to import the app module.
private extension String {
    static let who = "who"
    static let de = "de"
}
