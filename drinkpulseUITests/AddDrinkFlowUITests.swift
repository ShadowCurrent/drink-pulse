import XCTest

/// AddDrink complete-flow coverage (plan-0032, step 3).
///
/// Complements the narrow regression files
/// (`AddDrinkPickerFilterUITests`, `VolumeServingUITests`) by exercising the
/// AddDrink feature end to end:
/// - the drink-type grid lists the drink categories;
/// - the full log flow: open → pick a category → detail → Save → the new event
///   appears in History;
/// - the quantity `×N` control changes the logged *count* (per-portion, not
///   volume — `displayName` appends "×N" when `quantity > 1`);
/// - the custom-name path: a typed name is what History renders for the event.
///
/// All locators key off app-rendered ENGLISH text (the grid tile labels, the
/// `navigationBars[...]` titles, the "Save"/"Cancel" toolbar buttons, the
/// "Custom Name" text-field accessibility label, and the combined EventRow
/// button label). The app's strings are English-only, so this is locale-safe;
/// the simulator system locale is irrelevant here.
///
/// Seed: `-dp_uitest YES` inserts ONE 500 ml 5% beer named "Beer". The seeded
/// row therefore reads "Beer" with NO "×N" suffix and no custom name, so the
/// tests assert on a *distinguishing* attribute of the newly-logged event
/// (a typed custom name, or the "×N" quantity suffix) rather than a bare count.
///
/// Picker note (matches the sibling files): wheel content is not surfaced as
/// `staticTexts`; the selected row is read/adjusted via `pickerWheels`.
@MainActor
final class AddDrinkFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Builds and launches the app with the deterministic metric seed. Kept off
    /// the nonisolated `setUpWithError` override so the MainActor-isolated XCUI
    /// calls run on the MainActor.
    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        app.launch()
    }

    // MARK: - Drink-type grid shows categories

    /// The Add Drink grid must list the drink categories. Asserts a
    /// representative spread of the `DrinkTypePreset.all` tiles is present by
    /// their English tile labels (each tile is a Button with
    /// `accessibilityLabel = preset.name`).
    func test_drinkTypeGrid_showsCategories() throws {
        launchApp()
        openAddDrinkSheet()

        for category in ["Beer", "Wine", "Cider", "Vodka", "Whiskey", "Cocktail"] {
            let tile = app.buttons[category]
            XCTAssertTrue(tile.waitForExistence(timeout: 5),
                          "Drink-type grid should show a '\(category)' category tile")
        }
    }

    // MARK: - Full log flow: open → category → detail → Save → History

    /// Logs a Wine with a custom name and confirms it appears in History.
    /// The custom name distinguishes the new event from the pre-seeded "Beer".
    func test_fullLogFlow_savedEvent_appearsInHistory() throws {
        launchApp()
        openAddDrinkSheet()

        // Pick a category whose detail screen is titled by the preset name.
        let wineTile = app.buttons["Wine"]
        XCTAssertTrue(wineTile.waitForExistence(timeout: 10),
                      "Wine tile should be visible in the Add Drink grid")
        wineTile.tap()

        XCTAssertTrue(app.navigationBars["Wine"].waitForExistence(timeout: 5),
                      "Wine detail screen navigation bar should appear")

        let customName = "Barolo Riserva"
        typeCustomName(customName)
        save(on: "Wine")

        // The sheet dismisses on save; navigate to History and find the new row.
        openHistoryTab()
        let savedRow = eventButton(containing: customName)
        XCTAssertTrue(savedRow.waitForExistence(timeout: 10),
                      "The newly-logged '\(customName)' event should appear in History")
    }

    // MARK: - Quantity ×N control changes the logged count

    /// Setting the amount wheel to 2 portions must log an event whose History
    /// name carries the "×2" suffix (`displayName` appends "×N" for quantity > 1).
    /// The seeded single beer renders as plain "Beer" (no suffix), so the "×2"
    /// row is unambiguously the new multi-portion event — proving the control
    /// changed the *count*, not the per-portion volume.
    func test_quantityControl_logsMultiplePortions_showsTimesNInHistory() throws {
        launchApp()
        openAddDrinkSheet()

        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 10),
                      "Beer tile should be visible in the Add Drink grid")
        beerTile.tap()
        XCTAssertTrue(app.navigationBars["Beer"].waitForExistence(timeout: 5),
                      "Beer detail screen navigation bar should appear")

        // Three wheels: [0] volume, [1] strength, [2] amount (the "N×" picker).
        let amountWheel = app.pickerWheels.element(boundBy: 2)
        XCTAssertTrue(amountWheel.waitForExistence(timeout: 5),
                      "Amount (quantity) picker wheel should be present")
        amountWheel.adjust(toPickerWheelValue: "2×")
        XCTAssertEqual(amountWheel.value as? String, "2×",
                       "Amount wheel should now read '2×'")

        save(on: "Beer")

        openHistoryTab()
        let multiRow = eventButton(containing: "×2")
        XCTAssertTrue(multiRow.waitForExistence(timeout: 10),
                      "A 2-portion beer should appear in History with a '×2' suffix")
    }

    // MARK: - Custom name path

    /// A typed custom name is what History renders for the event — it overrides
    /// the preset/serving-derived name entirely (see `ConsumptionEvent.baseName`).
    func test_customName_isRenderedInHistory() throws {
        launchApp()
        openAddDrinkSheet()

        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 10),
                      "Beer tile should be visible in the Add Drink grid")
        beerTile.tap()
        XCTAssertTrue(app.navigationBars["Beer"].waitForExistence(timeout: 5),
                      "Beer detail screen navigation bar should appear")

        let customName = "Hazy Session IPA"
        typeCustomName(customName)
        save(on: "Beer")

        openHistoryTab()
        XCTAssertTrue(eventButton(containing: customName).waitForExistence(timeout: 10),
                      "The custom name '\(customName)' should be rendered for the logged event")
    }

    // MARK: - Helpers

    private func openAddDrinkSheet() {
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
                      "Home tab should be accessible after launch")

        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "Add Drink button should be visible after launch")
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5),
                      "Add Drink navigation bar should appear")
    }

    /// Types into the custom-name field, addressed by its English
    /// `accessibilityLabel` ("Custom Name"). Taps to focus before typing.
    private func typeCustomName(_ text: String) {
        let field = app.textFields["Custom Name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5),
                      "Custom Name text field should be present in the detail screen")
        field.tap()
        field.typeText(text)
    }

    /// Taps Save on the given detail screen's navigation bar.
    private func save(on detailTitle: String) {
        let saveButton = app.navigationBars[detailTitle].buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5),
                      "Save button should be present on the \(detailTitle) detail screen")
        saveButton.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5),
                      "Saving should dismiss the Add Drink sheet")
    }

    private func openHistoryTab() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should be accessible")
        tab.tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5),
                      "History screen should appear")
    }

    /// The EventRow is a `.buttonStyle(.plain)` Button whose combined label
    /// carries the rendered drink name — match it by substring.
    private func eventButton(containing substring: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
    }
}
