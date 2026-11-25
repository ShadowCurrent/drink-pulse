import XCTest

/// Add Drink step 1 as a sectioned list with Recent and search (plan 0047, D0047-1/4/5).
@MainActor
final class AddDrinkTypeListUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        app.launch()
    }

    // MARK: - Sections

    func test_step1_showsSections_andNoRecent_whenNoHistory() throws {
        launch()
        openAddDrink()
        for id in ["beerCider", "wine", "spirits"] {
            XCTAssertTrue(sectionHeader(id).waitForExistence(timeout: 5),
                          "Section '\(id)' should be listed")
        }
        // The last section sits below the fold on a phone; scroll until it appears.
        let mixed = sectionHeader("mixed")
        for _ in 0..<4 where !mixed.exists { app.swipeUp() }
        XCTAssertTrue(mixed.exists, "Section 'mixed' should be listed")
        XCTAssertFalse(sectionHeader("recent").exists,
                       "Recent must be hidden when there is no history")
    }

    // MARK: - Search

    func test_search_cog_showsBrandyAndCognac_only() throws {
        launch()
        openAddDrink()
        search(for: "cog")
        XCTAssertTrue(app.buttons["Brandy & Cognac"].waitForExistence(timeout: 5),
                      "Searching 'cog' should find the Brandy & Cognac row")
        XCTAssertFalse(app.buttons["addDrink.type.beer"].exists,
                       "Searching 'cog' should hide Beer")
    }

    func test_search_noMatch_showsSearchEmptyState() throws {
        launch()
        openAddDrink()
        search(for: "zzz")
        let typeRows = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "addDrink.type."))
        XCTAssertTrue(typeRows.firstMatch.waitForNonExistence(timeout: 5),
                      "No drink type should match 'zzz'")
        XCTAssertTrue(app.descendants(matching: .any)["addDrink.searchEmpty"].exists,
                      "The search empty state should be shown")
    }

    // MARK: - Recent

    func test_recentRow_opensStep2_withStoredServing() throws {
        launch()
        openAddDrink()
        openType("wine", title: "Wine")
        let volumeWheel = app.pickerWheels.element(boundBy: 0)
        XCTAssertTrue(volumeWheel.waitForExistence(timeout: 5))
        volumeWheel.adjust(toPickerWheelValue: "Carafe · 500 ml")
        let logged = volumeWheel.value as? String
        XCTAssertEqual(logged, "Carafe · 500 ml")
        typeCustomName("Recent Wine")
        confirm()

        openAddDrink()
        XCTAssertTrue(sectionHeader("recent").waitForExistence(timeout: 5),
                      "Recent should appear after a drink is logged")
        let row = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Recent Wine")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "The logged drink should be a Recent row")
        row.tap()

        XCTAssertTrue(app.navigationBars["Wine"].waitForExistence(timeout: 5),
                      "A Recent row opens step 2 for its type")
        XCTAssertEqual(app.pickerWheels.element(boundBy: 0).value as? String, logged,
                       "Step 2 keeps the Recent drink's serving")
        XCTAssertEqual(app.textFields["Custom Name"].value as? String, "Recent Wine",
                       "Step 2 keeps the Recent drink's name")
    }

    func test_recent_showsAtMostThree() throws {
        launch()
        for (id, title) in [("beer", "Beer"), ("wine", "Wine"), ("cider", "Cider"), ("vodka", "Vodka")] {
            openAddDrink()
            openType(id, title: title)
            confirm()
        }
        openAddDrink()
        XCTAssertTrue(sectionHeader("recent").waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "addDrink.recentRow").count, 3,
                       "Recent shows at most three drinks")
    }

    // MARK: - Helpers

    private func sectionHeader(_ id: String) -> XCUIElement {
        app.staticTexts["addDrink.section.\(id)"]
    }

    private func openAddDrink() {
        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10), "Add Drink button should exist")
        addButton.tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5),
                      "Add Drink step 1 should appear")
    }

    private func openType(_ id: String, title: String) {
        let row = app.buttons["addDrink.type.\(id)"]
        for _ in 0..<4 where !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 5), "\(title) row should be listed")
        row.tap()
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5),
                      "\(title) step 2 should appear")
    }

    private func search(for text: String) {
        // `.automatic` drawer (D0047-5): on iOS 27.2 it rests collapsed under the large title
        // and a pull-down on the list reveals it.
        let field = app.searchFields.firstMatch
        if !field.waitForExistence(timeout: 2) {
            app.collectionViews.firstMatch.swipeDown()
        }
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Step 1 should offer a search field")
        field.tap()
        field.typeText(text)
    }

    private func typeCustomName(_ text: String) {
        let field = app.textFields["Custom Name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(text)
    }

    private func confirm() {
        let button = app.buttons["drinkForm.confirm"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Step 2 should offer the confirm button")
        button.tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5),
                      "Confirming should dismiss the Add Drink sheet")
    }
}
