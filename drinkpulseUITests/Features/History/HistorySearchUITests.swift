import XCTest

/// History List search by custom name (plan-0039).
///
/// Dataset `search`: "Guinness" today (500 ml), "Tyskie" 200 days ago
/// (500 ml, outside the 90-day list window) and an unnamed 330 ml beer today.
/// The search row is the app's own inline field (`HistorySearchField`), so its
/// controls are matched by accessibility identifier or by app-rendered
/// English text, never by system-localized labels.
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

    /// Vertical-axis text field: matched by identifier, whatever its element type.
    private var searchField: XCUIElement {
        app.descendants(matching: .any)["history.search.field"]
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
        XCTAssertFalse(app.buttons["Cancel"].waitForExistence(timeout: 2),
                       "Return should end editing, so the Cancel button goes away")
        XCTAssertFalse(app.keyboards.firstMatch.exists, "Return should dismiss the keyboard")
    }

    func test_clearButton_restoresFullList() throws {
        search("guin")
        XCTAssertTrue(row(containing: "Guinness").waitForExistence(timeout: 5))
        let clear = app.buttons["history.search.clear"]
        XCTAssertTrue(clear.waitForExistence(timeout: 5), "Search field should show a clear button")
        clear.tap()
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
        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "Cancel should show while searching")
        cancel.tap()
        XCTAssertTrue(row(containing: "330 ml").waitForExistence(timeout: 5),
                      "After cancel the unnamed 330 ml row should be back")
        XCTAssertTrue(app.staticTexts["No earlier entries"].waitForExistence(timeout: 10),
                      "After cancel the paginated list should load to its end footer")
        XCTAssertFalse(app.segmentedControls.buttons["Named"].exists,
                       "After cancel the scope picker should be gone")
    }

    func test_segmentSwitch_keepsPickerInPlace_andHidesSearchInCalendar() throws {
        let listSegment = app.segmentedControls.buttons["List"]
        XCTAssertTrue(listSegment.waitForExistence(timeout: 10))
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "List shows the search field")
        let listFrame = listSegment.frame
        app.segmentedControls.buttons["Calendar"].tap()
        XCTAssertTrue(searchField.waitForNonExistence(timeout: 5),
                      "Calendar should not show the search field")
        XCTAssertEqual(listSegment.frame.minY, listFrame.minY, accuracy: 1,
                       "The List/Calendar picker must not move when the segment changes")
        listSegment.tap()
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "List shows the search field again")
        XCTAssertEqual(listSegment.frame.minY, listFrame.minY, accuracy: 1,
                       "The picker must stay in place after returning to List")
    }
}
