import XCTest

@MainActor
final class AddDrinkFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        app.launch()
    }

    // MARK: - Drink-type list shows categories

    func test_drinkTypeList_showsCategories() throws {
        launchApp()
        openAddDrinkSheet()

        for category in ["Beer", "Wine", "Cider", "Vodka", "Whiskey", "Cocktail"] {
            // The list is lazy: rows below the fold exist only once scrolled into view.
            let tile = app.buttons[category]
            for _ in 0..<4 where !tile.exists { app.swipeUp() }
            XCTAssertTrue(tile.waitForExistence(timeout: 5),
                          "Drink-type list should show a '\(category)' category row")
        }
    }

    // MARK: - Full log flow: open → category → detail → Save → History

    func test_fullLogFlow_savedEvent_appearsInHistory() throws {
        launchApp()
        openAddDrinkSheet()

        let wineTile = app.buttons["Wine"]
        XCTAssertTrue(wineTile.waitForExistence(timeout: 10),
                      "Wine row should be visible in the Add Drink list")
        wineTile.tap()

        XCTAssertTrue(app.navigationBars["Wine"].waitForExistence(timeout: 5),
                      "Wine detail screen navigation bar should appear")

        let customName = "Barolo Riserva"
        typeCustomName(customName)
        save(on: "Wine")

        openHistoryTab()
        let savedRow = eventButton(containing: customName)
        XCTAssertTrue(savedRow.waitForExistence(timeout: 10),
                      "The newly-logged '\(customName)' event should appear in History")
    }

    // MARK: - Quantity ×N control changes the logged count

    func test_quantityControl_logsMultiplePortions_showsTimesNInHistory() throws {
        launchApp()
        openAddDrinkSheet()

        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 10),
                      "Beer row should be visible in the Add Drink list")
        beerTile.tap()
        XCTAssertTrue(app.navigationBars["Beer"].waitForExistence(timeout: 5),
                      "Beer detail screen navigation bar should appear")

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

    func test_customName_isRenderedInHistory() throws {
        launchApp()
        openAddDrinkSheet()

        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 10),
                      "Beer row should be visible in the Add Drink list")
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

    // MARK: - Sheet dismissal preserves originating tab

    func test_originatingHistoryTab_listCancel_returnsToHistory() throws {
        launchApp()
        openAddDrinkSheet(from: "History")

        let cancel = app.navigationBars["Add Drink"].buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "Cancel should be discoverable before dismissal")
        cancel.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5),
                      "List cancel should return to the originating History tab")
    }

    /// Settings has no Add Drink button since plan 0044 (`ShellNavigationUITests
    /// .test_addDrinkButton_absentOnSettings`), so the originating-tab save runs from Insights.
    func test_originatingInsightsTab_save_persistsAndReturnsToInsights() throws {
        launchApp()
        openAddDrinkSheet(from: "Insights")

        let beer = app.buttons["Beer"]
        XCTAssertTrue(beer.waitForExistence(timeout: 5))
        beer.tap()
        XCTAssertTrue(app.navigationBars["Beer"].waitForExistence(timeout: 5))
        typeCustomName("Originating tab save")
        save(on: "Beer")

        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5),
                      "Saving should return to the originating Insights tab")
        openHistoryTab()
        XCTAssertTrue(eventButton(containing: "Originating tab save").waitForExistence(timeout: 10),
                      "Saving should persist the uniquely named event in History")
    }

    // MARK: - Step 2 navigation bar (HIG multi-step sheet: Back + confirm, no Cancel)

    func test_detailStep_navigationBar_offersBackAndConfirm_withoutCancel() throws {
        launchApp()
        let detailBar = openDetailStep("Beer")

        XCTAssertTrue(detailBar.buttons["BackButton"].waitForExistence(timeout: 5),
                      "Step 2 should offer the system Back button")
        let confirm = app.buttons["drinkForm.confirm"]
        XCTAssertTrue(confirm.exists, "Step 2 should offer the confirm button")
        // `Button(role: .confirm)` has no title of ours; VoiceOver needs the system label.
        XCTAssertFalse(confirm.label.isEmpty, "The confirm button must have an accessibility label")
        print("drinkForm.confirm label: \(confirm.label)")
        XCTAssertFalse(detailBar.buttons["Cancel"].exists,
                       "Step 2 must not show Cancel next to Back and confirm (HIG: avoid all three)")
    }

    /// Regression: a leading Cancel next to the system Back button made a cancelled interactive
    /// pop drop the Back button for good on iOS 27, leaving Cancel in its place.
    func test_detailStep_cancelledEdgeSwipe_keepsBackButton() throws {
        launchApp()
        let detailBar = openDetailStep("Beer")
        let back = detailBar.buttons["BackButton"]
        XCTAssertTrue(back.waitForExistence(timeout: 5), "Back button should exist before the swipe")

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.85))
            .withOffset(CGVector(dx: 2, dy: 0))
        start.press(forDuration: 0.05,
                    thenDragTo: start.withOffset(CGVector(dx: 70, dy: 0)),
                    withVelocity: .slow,
                    thenHoldForDuration: 0.1)

        XCTAssertTrue(detailBar.waitForExistence(timeout: 5),
                      "A short edge swipe should be cancelled and stay on step 2")
        _ = back.waitForNonExistence(timeout: 2)
        XCTAssertTrue(back.exists, "Back button must survive a cancelled edge swipe")
    }

    // MARK: - Drag indicator

    /// Regression: the Add Drink sheet hid the grabber (`.automatic` visibility) while Edit Drink
    /// showed it, so nothing hinted that a swipe down dismisses the sheet. The grabber is an
    /// in-app element; its label comes from the app's English localization.
    func test_addDrinkSheet_showsDragIndicator_onBothSteps() throws {
        launchApp()
        openAddDrinkSheet()
        let grabber = app.buttons["Sheet Grabber"]
        XCTAssertTrue(grabber.waitForExistence(timeout: 5),
                      "Add Drink step 1 should show the sheet drag indicator, like Edit Drink")

        app.buttons["Beer"].tap()
        XCTAssertTrue(app.navigationBars["Beer"].waitForExistence(timeout: 5))
        XCTAssertTrue(grabber.exists, "The drag indicator should stay visible on step 2")
    }

    // MARK: - Helpers

    private func openDetailStep(_ category: String) -> XCUIElement {
        openAddDrinkSheet()
        let tile = app.buttons[category]
        XCTAssertTrue(tile.waitForExistence(timeout: 10), "\(category) tile should be visible")
        tile.tap()
        let detailBar = app.navigationBars[category]
        XCTAssertTrue(detailBar.waitForExistence(timeout: 5), "\(category) detail screen should appear")
        return detailBar
    }

    private func openAddDrinkSheet() {
        openAddDrinkSheet(from: UITestTabs.today)
    }

    private func openAddDrinkSheet(from tabName: String) {
        let tab = app.tabBars.buttons[tabName]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "\(tabName) tab should be accessible after launch")
        tab.tap()
        XCTAssertTrue(app.navigationBars[tabName].waitForExistence(timeout: 5))

        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "Add Drink button should be visible after launch")
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5),
                      "Add Drink navigation bar should appear")
    }

    private func typeCustomName(_ text: String) {
        let field = app.textFields["Custom Name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5),
                      "Custom Name text field should be present in the detail screen")
        field.tap()
        field.typeText(text)
    }

    private func save(on detailTitle: String) {
        let saveButton = app.buttons["drinkForm.confirm"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5),
                      "Confirm button should be present on the \(detailTitle) detail screen")
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

    private func eventButton(containing substring: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
    }
}
