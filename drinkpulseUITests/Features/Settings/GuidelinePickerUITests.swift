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

    /// Choosing a different guideline moves the trait with it.
    func test_guidelinePicker_selectionTraitFollowsChoice() throws {
        launchApp()
        openSettings()
        openGuidelineSheet()

        let germany = row(RowID.de)
        XCTAssertTrue(germany.waitForExistence(timeout: 5),
                      "Germany row should be present in the guideline sheet")
        germany.tap()

        // Selecting dismisses the sheet; reopen it to inspect the new state.
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

    /// Pins the B9-3 conversion (D-05 = `now`): both guideline screens left
    /// `.insetGrouped` `List` for a `ScrollView` + titleless `SettingsSection`
    /// glass card.
    ///
    /// "All six rows present in the hierarchy at the `.medium` detent" is the
    /// load-bearing assertion: a `List` builds rows lazily, a `VStack` inside a
    /// `ScrollView` builds all of them. So this is both the objective signature of
    /// the new layout and the proof that no choice was dropped in the rewrite.
    ///
    /// The onboarding half of the conversion is covered by the existing
    /// `OnboardingFlowUITests` rather than duplicated here: its
    /// `selectGuideline(in:named:)` matches `app.buttons` by label, so it is
    /// layout-agnostic, and its pass is the proof that `GuidelineStep` still
    /// selects and advances. That is deliberate coverage, not a gap.
    func test_guidelinePicker_rendersEveryChoiceAsCardRow_andSelectionStillWorks() throws {
        launchApp()
        openSettings()
        openGuidelineSheet()

        // Every pickable guideline must be in the hierarchy, not just the ones a
        // lazy container happened to realise.
        for identifier in RowID.all {
            let element = row(identifier)
            XCTAssertTrue(element.waitForExistence(timeout: 5),
                          "Guideline '\(identifier)' should render as a card row after the conversion")
        }

        // Leaving List gave up its default row insets; GuidelineChoiceRow supplies
        // its own vertical padding inside the Button's contentShape so the row keeps
        // a real hit target. CLAUDE.md sets 44pt as the floor.
        //
        // Hittability is asserted only for rows guaranteed on screen: at the .medium
        // detent a swipe can drag the sheet rather than the scroll view, so this test
        // deliberately never scrolls.
        for identifier in [RowID.who, RowID.de] {
            let element = row(identifier)
            XCTAssertTrue(element.isHittable,
                          "Guideline row '\(identifier)' should be hittable inside the glass card")
            XCTAssertGreaterThanOrEqual(element.frame.height, 44,
                                        "Guideline row '\(identifier)' must meet the 44pt minimum hit target")
        }

        // The picker still works end to end after the restyle.
        row(RowID.de).tap()
        XCTAssertFalse(app.navigationBars["Guideline"].waitForExistence(timeout: 3),
                       "Selecting a guideline should dismiss the picker sheet")
        XCTAssertTrue(app.buttons["Germany (DHS)"].waitForExistence(timeout: 5),
                      "Settings guideline row should read the newly chosen guideline")
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
    private func row(_ identifier: String) -> XCUIElement {
        app.buttons[identifier].firstMatch
    }
}

/// The accessibility identifiers `GuidelineChoiceRow` emits, spelled out in full so
/// the assertions name exactly what they address. Kept as plain strings because the
/// UI-test target does not import the app module.
private enum RowID {
    static let who = "guidelineChoiceRow.who"
    static let de = "guidelineChoiceRow.de"
    static let uk = "guidelineChoiceRow.uk"
    static let us = "guidelineChoiceRow.us"
    static let au = "guidelineChoiceRow.au"
    static let ca = "guidelineChoiceRow.ca"

    /// Every pickable guideline, matching `GuidelineChoice.selectable`.
    static let all = [who, de, uk, us, au, ca]
}
