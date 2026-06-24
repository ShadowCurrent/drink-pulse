import XCTest

/// plan-0031 UI coverage: serving-name provenance (a logged drink's name stays
/// stable across a unit-mode switch, driven by `enteredUnit`) and imperial pint
/// rendering in the Add-Drink serving picker.
///
/// Accessibility note (matches HistoryUnitDisplayUITests): the EventRow is a
/// `.buttonStyle(.plain)` Button whose combined label is on the Button — query
/// via `app.buttons.matching(…)`.
@MainActor
final class VolumeServingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Builds and launches the app with the given extra launch arguments. Kept
    /// off the nonisolated `setUpWithError` override so the MainActor-isolated
    /// XCUI calls run on the MainActor.
    private func launchApp(_ extraArguments: [String]) {
        app = XCUIApplication()
        app.launchArguments += extraArguments
        app.launch()
    }

    /// A 568 ml beer logged in imperial renders as "Pint". Switching the profile
    /// unit to US must keep the name "Pint" (provenance), NOT flip it to the
    /// US-region name "Stovepipe".
    func test_provenance_nameStaysPintAcrossUnitSwitch() throws {
        launchApp([
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
            "-dp_uitest_provenance", "YES",
        ])

        openHistoryTab()
        let pintRow = eventButton(containing: "Pint")
        XCTAssertTrue(pintRow.waitForExistence(timeout: 10),
                      "Imperial-entered 568 ml beer should render as 'Pint'")
        XCTAssertFalse(eventButton(containing: "Stovepipe").waitForExistence(timeout: 2),
                       "Provenance name must not be the US 'Stovepipe' in metric mode")

        // Switch the profile unit to US — the serving name must stay "Pint".
        switchVolumeUnit(to: "US fl oz")
        openHistoryTab()
        XCTAssertTrue(eventButton(containing: "Pint").waitForExistence(timeout: 5),
                      "After switching to US, provenance keeps the name 'Pint'")
        XCTAssertFalse(eventButton(containing: "Stovepipe").waitForExistence(timeout: 2),
                       "Provenance must override the current-profile US name 'Stovepipe'")
    }

    /// In imperial mode the beer serving picker renders a pint label
    /// (e.g. "Pint · 1 pint") rather than fluid ounces.
    func test_imperialBeerPicker_showsPintServing() throws {
        launchApp([
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "imperial",
        ])

        openAddDrinkSheet()
        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 10), "Beer tile should be visible")
        beerTile.tap()
        XCTAssertTrue(app.navigationBars["Beer"].waitForExistence(timeout: 5),
                      "Beer detail screen should appear")

        let volumeWheel = app.pickerWheels.element(boundBy: 0)
        XCTAssertTrue(volumeWheel.waitForExistence(timeout: 5),
                      "Volume picker wheel should be present")
        let selectedValue = volumeWheel.value as? String ?? ""
        XCTAssertTrue(selectedValue.contains("pint"),
                      "Imperial beer serving label should render in pints, got '\(selectedValue)'")
    }

    // MARK: - Helpers

    private func openHistoryTab() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should be accessible")
        tab.tap()
    }

    private func eventButton(containing substring: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
    }

    private func openAddDrinkSheet() {
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10), "Home tab should be accessible")
        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add Drink button should be visible")
        addButton.tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5),
                      "Add Drink navigation bar should appear")
    }

    private func switchVolumeUnit(to label: String) {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 10), "Settings tab should be accessible")
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
