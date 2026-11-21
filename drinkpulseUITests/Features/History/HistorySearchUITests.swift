import XCTest

/// History List search by custom name (plan-0039), native `.searchable` since plan 0045.
///
/// Dataset `search`: "Guinness" today (500 ml), "Tyskie" 200 days ago
/// (500 ml, outside the list window) and an unnamed 330 ml beer today.
/// System search controls (field, clear, Cancel) are matched by element type and
/// position, never by label (the simulator locale is Polish); scopes use the
/// app-owned labels All / Named / Unnamed.
@MainActor
final class HistorySearchUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
            "-dp_uitest_dataset", "search",
        ]
        app.launch()
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should exist")
        tab.tap()
    }

    // MARK: - Helpers

    private var searchField: XCUIElement {
        app.searchFields.firstMatch
    }

    /// The system clear button inside the search field.
    private var clearButton: XCUIElement {
        searchField.buttons.firstMatch
    }

    /// The system Cancel button: the bar button to the right of the search field, on its row.
    private func cancelButton() -> XCUIElement? {
        let field = searchField.frame
        return app.navigationBars.buttons.allElementsBoundByIndex.first { button in
            let frame = button.frame
            return frame.minX >= field.maxX - 1 && frame.midY > field.minY && frame.midY < field.maxY
        }
    }

    private func waitForCancelButton(timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if let button = cancelButton() { return button }
            usleep(150_000)
        } while Date() < deadline
        return nil
    }

    private func row(containing substring: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
    }

    private func activateSearch() {
        XCTAssertTrue(searchField.waitForExistence(timeout: 10), "Search field should exist")
        searchField.tap()
    }

    private func search(_ text: String) {
        activateSearch()
        searchField.typeText(text)
    }

    private func tapScope(_ label: String) {
        let scope = app.segmentedControls.buttons[label]
        XCTAssertTrue(scope.waitForExistence(timeout: 5), "Scope '\(label)' should be shown")
        scope.tap()
    }

    // MARK: - Tests

    func test_search_filtersListToMatchingName() throws {
        XCTAssertTrue(row(containing: "330 ml").waitForExistence(timeout: 10),
                      "Unfiltered list should show the unnamed 330 ml row")
        search("guin")
        XCTAssertTrue(row(containing: "Guinness").waitForExistence(timeout: 5),
                      "Search 'guin' should show the Guinness row")
        XCTAssertFalse(row(containing: "330 ml").exists,
                       "Search 'guin' should hide the unnamed 330 ml row")
    }

    func test_search_findsEntryOlderThanListWindow() throws {
        search("tysk")
        XCTAssertTrue(row(containing: "Tyskie").waitForExistence(timeout: 5),
                      "Search should find Tyskie, logged 200 days ago (outside the list window)")
    }

    func test_returnKey_dismissesKeyboard_andKeepsQuery() throws {
        search("guin\n")
        XCTAssertTrue(row(containing: "Guinness").waitForExistence(timeout: 5),
                      "Return should keep the 'guin' results")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3),
                      "Return should dismiss the keyboard")
    }

    func test_clearButton_restoresFullList() throws {
        search("guin")
        XCTAssertTrue(row(containing: "Guinness").waitForExistence(timeout: 5))
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5), "Search field should show a clear button")
        clearButton.tap()
        XCTAssertTrue(row(containing: "330 ml").waitForExistence(timeout: 5),
                      "Clearing the query should bring the 330 ml row back")
    }

    func test_unnamedScope_withText_showsExplanation() throws {
        activateSearch()
        tapScope("Unnamed")
        searchField.typeText("a")
        let explanation = app.staticTexts[
            "Unnamed drinks have no name to match. Switch to All or Named to search by name."
        ]
        XCTAssertTrue(explanation.waitForExistence(timeout: 5),
                      "Unnamed scope plus text should explain that unnamed drinks have no name")
    }

    func test_cancel_resetsScopeAndShowsFullList() throws {
        activateSearch()
        tapScope("Named")
        XCTAssertTrue(app.collectionViews["history.search.results"].waitForExistence(timeout: 5),
                      "Named scope should switch to search results")
        let cancel = try XCTUnwrap(waitForCancelButton(timeout: 5), "Cancel should show while searching")
        cancel.tap()
        XCTAssertTrue(row(containing: "330 ml").waitForExistence(timeout: 5),
                      "After cancel the unnamed 330 ml row should be back")
        XCTAssertTrue(app.staticTexts["No earlier entries"].waitForExistence(timeout: 10),
                      "After cancel the paginated list should load to its end footer")
        XCTAssertFalse(app.segmentedControls.buttons["Named"].exists,
                       "After cancel the scope picker should be gone")
    }

    func test_segmentSwitch_keepsPickerInPlace_andHidesSearchInCalendar() throws {
        let listSegment = app.navigationBars.segmentedControls.buttons["List"]
        XCTAssertTrue(listSegment.waitForExistence(timeout: 10))
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "List shows the search field")
        let listFrame = listSegment.frame
        app.navigationBars.segmentedControls.buttons["Calendar"].tap()
        XCTAssertTrue(searchField.waitForNonExistence(timeout: 5),
                      "Calendar should not show the search field")
        XCTAssertEqual(listSegment.frame.minY, listFrame.minY, accuracy: 1,
                       "The List/Calendar picker must not move when the segment changes")
        listSegment.tap()
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "List shows the search field again")
        XCTAssertEqual(listSegment.frame.minY, listFrame.minY, accuracy: 1,
                       "The picker must stay in place after returning to List")
    }

    /// Review focus 3: the same row actions on search results; a deleted row leaves the results.
    func test_swipeDelete_onSearchResult_removesIt() throws {
        search("guin")
        let guinness = row(containing: "Guinness")
        XCTAssertTrue(guinness.waitForExistence(timeout: 5), "Search should show Guinness")
        guinness.swipeLeft()
        let delete = app.buttons["history.row.delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "Swipe on a result should reveal Delete")
        delete.tap()
        XCTAssertTrue(guinness.waitForNonExistence(timeout: 5), "The deleted row should leave the results")
    }
}
