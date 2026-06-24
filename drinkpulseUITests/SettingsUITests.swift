import XCTest

/// UI tests for the Settings screen, complementing `ExportUITests` (which
/// covers the Data → Export save-panel flow). These assert the remaining
/// user-visible Settings behaviours:
///
/// - **Theme swatch** selection takes effect (selected swatch flips its
///   `.isSelected` trait; the previously selected one clears).
/// - **Appearance mode** picker reflects the chosen Light/Dark/System option.
/// - **Guideline picker** change reflects on the row and *persists* across a
///   tab round-trip.
/// - **Unit-system switch** reflects in displayed volumes on another screen
///   (History: "500 ml" → an "fl oz" value), using the `-dp_uitest` seed.
/// - **App Lock** row is present and addressable.
/// - **Data** section is visible.
///
/// Locale independence: every element is keyed off the app's own English text,
/// nav/tab bars, or picker `.value` — never a system-process control. The app
/// is English-only, so asserting on app-rendered text is safe even though the
/// simulator's system locale is Polish.
///
/// App Lock note: the "App Lock" row is a deep-link action (it opens the system
/// Settings app via `UIApplication.openSettingsURLString`) — it is **not** an
/// in-app biometric toggle, so there is no Face ID / passcode prompt to drive.
/// The test therefore asserts the row's presence and addressability and does
/// **not** tap it (tapping would leave the app for system-process UI). See
/// `test_appLockRow_isPresentAndAddressable`.
@MainActor
final class SettingsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Builds and launches the app with the deterministic seed (one 500 ml 5%
    /// beer) and onboarding skipped. Kept off the nonisolated `setUpWithError`
    /// override so the MainActor-isolated XCUI calls run on the MainActor.
    private func launchApp(unit: String = "metric") {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", unit,
        ]
        app.launch()
    }

    // MARK: - Theme / appearance

    /// Tapping a non-selected theme swatch makes it the selected swatch and
    /// clears the previously selected one. Swatches are buttons whose
    /// accessibilityLabel is the theme name with an `.isSelected` trait when
    /// active (see `AppearanceCard.ThemeSwatch`).
    func test_themeSwitch_selectsTappedSwatch() throws {
        launchApp()
        openSettings()

        // The three swatches are buttons labelled by theme name; the active one
        // carries the `.isSelected` trait (see AppearanceCard.ThemeSwatch). The
        // theme persists in @AppStorage (UserDefaults), which survives across
        // launches, so the starting theme is not asserted — the test instead
        // moves selection to a different swatch and verifies the trait follows.
        let swatches = ["Ember", "Forest", "Iris"].map { app.buttons[$0] }
        XCTAssertTrue(swatches[0].waitForExistence(timeout: 5),
                      "Theme swatches should be visible in Settings")
        for s in swatches {
            XCTAssertTrue(s.exists, "Each theme swatch should be present")
        }

        guard let currentlySelected = swatches.first(where: { $0.isSelected }) else {
            XCTFail("Exactly one theme swatch should start selected")
            return
        }
        let target = swatches.first { !$0.isSelected }!

        target.tap()

        XCTAssertTrue(target.isSelected,
                      "Tapped swatch should become the selected theme")
        XCTAssertFalse(currentlySelected.isSelected,
                       "Previously selected swatch should clear once another is tapped")
        XCTAssertEqual(swatches.filter { $0.isSelected }.count, 1,
                       "Exactly one theme swatch should be selected at a time")
    }

    /// The Appearance-mode picker (.menu) reflects the chosen option in its
    /// button label. Switch System → Dark and assert the label updates.
    func test_appearanceMode_reflectsSelectedOption() throws {
        launchApp()
        openSettings()

        // The .menu Picker (.labelsHidden) surfaces as a button whose label is
        // "<picker title>, <selected value>", e.g. "Appearance, System". The
        // mode persists in @AppStorage (UserDefaults) across launches, so the
        // starting value is not asserted — the test picks an option that differs
        // from the current one and verifies the button label follows.
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

    /// Changing the guideline in the picker sheet reflects on the Settings row
    /// and persists across a tab round-trip (the seed profile starts on WHO).
    func test_guidelinePicker_changePersists() throws {
        launchApp()
        openSettings()

        // The guideline row is a plain button labelled exactly the choice's
        // displayName. Seed profile is WHO.
        let whoRow = app.buttons["WHO (Global)"]
        XCTAssertTrue(whoRow.waitForExistence(timeout: 5),
                      "Guideline row should start on 'WHO (Global)'")
        whoRow.tap()

        // The sheet lists every choice; tap Germany.
        let germany = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Germany (DHS)'")
        ).firstMatch
        XCTAssertTrue(germany.waitForExistence(timeout: 5),
                      "Germany (DHS) option should appear in the guideline sheet")
        germany.tap()

        // Row now reflects the new choice.
        let germanyRow = app.buttons["Germany (DHS)"]
        XCTAssertTrue(germanyRow.waitForExistence(timeout: 5),
                      "Guideline row should update to 'Germany (DHS)' after selection")

        // Persistence: leave Settings and come back; the choice must stick.
        app.tabBars.buttons["History"].tap()
        openSettings()
        XCTAssertTrue(app.buttons["Germany (DHS)"].waitForExistence(timeout: 5),
                      "Guideline choice should persist across a tab round-trip")
        XCTAssertFalse(app.buttons["WHO (Global)"].exists,
                       "Old WHO choice must not reappear after switching")
    }

    // MARK: - Unit-system switch reflected in volumes

    /// Switching the volume unit in Settings changes how volumes render on the
    /// History screen: the seeded 500 ml beer shows in ml under metric and in
    /// fl oz under US. Complements `HistoryUnitDisplayUITests` by driving the
    /// switch from the Settings feature's perspective.
    func test_unitSwitch_reflectsInDisplayedVolumes() throws {
        launchApp(unit: "metric")

        // Baseline: History shows the metric volume.
        openHistory()
        XCTAssertTrue(eventRow(containing: "500 ml").waitForExistence(timeout: 10),
                      "Metric mode: History should show the seeded '500 ml' beer")

        // Switch to US fl oz in Settings.
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

        // History now renders the volume in fl oz, not ml.
        openHistory()
        XCTAssertTrue(eventRow(containing: "fl oz").waitForExistence(timeout: 5),
                      "US mode: History should render the volume in 'fl oz'")
        XCTAssertFalse(eventRow(containing: "500 ml").waitForExistence(timeout: 2),
                       "US mode: '500 ml' must not appear once the unit switched")
    }

    // MARK: - App Lock & Data section

    /// The "App Lock" row is present and addressable. It is a deep-link action
    /// (opens the system Settings app), not an in-app biometric toggle, so the
    /// test asserts presence/addressability only and does NOT tap it — tapping
    /// would leave the app for system-process UI that is locale-dependent and
    /// not reliably driveable.
    func test_appLockRow_isPresentAndAddressable() throws {
        launchApp()
        openSettings()

        let appLock = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'App Lock'")
        ).firstMatch
        // It sits below the fold; scroll if needed.
        if !appLock.waitForExistence(timeout: 5) {
            app.swipeUp()
        }
        XCTAssertTrue(appLock.waitForExistence(timeout: 5),
                      "App Lock row should be present in the Privacy section")
        XCTAssertTrue(appLock.isHittable,
                      "App Lock row should be addressable (hittable)")
    }

    /// The Data section's Export row is visible (the section header is decorative
    /// text; the row is the addressable, stable anchor — matching ExportUITests).
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
        // Give the form a moment to lay out before asserting deep rows.
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Settings navigation bar should appear")
    }

    private func openHistory() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10),
                      "History tab should be accessible")
        tab.tap()
    }

    /// The EventRow is a `.buttonStyle(.plain)` Button; its combined
    /// accessibilityLabel lives on the button, so match against buttons.
    private func eventRow(containing substring: String) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", substring)
        ).firstMatch
    }
}
