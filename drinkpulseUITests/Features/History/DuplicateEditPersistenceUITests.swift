import XCTest

@MainActor
final class DuplicateEditPersistenceUITests: XCTestCase {
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

    func test_editFreshDuplicate_survivesPastAutosaveWindow() throws {
        launchApp()

        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should be accessible")
        tab.tap()

        func eventButton(containing substring: String) -> XCUIElement {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
        }

        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Seeded beer row should be present")
        row.press(forDuration: 1.2)

        let duplicate = app.buttons["Duplicate"]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5), "Context menu should offer Duplicate")
        duplicate.tap()

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "500 ml")).count == 2 { break }
            usleep(150_000)
        }
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "500 ml")).count, 2,
                       "Duplicate should produce a second 500 ml beer row")

        let topRow = eventButton(containing: "500 ml")
        topRow.tap()

        let editNav = app.navigationBars["Edit Drink"]
        XCTAssertTrue(editNav.waitForExistence(timeout: 5), "Edit Drink sheet should open on the duplicate")

        let nameField = app.textFields["Custom Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Custom Name field should be present")
        nameField.tap()
        nameField.typeText("Regression Marker\n")

        Thread.sleep(forTimeInterval: 10)

        XCTAssertTrue(app.navigationBars["Edit Drink"].exists,
                      "Edit Drink sheet must still be open after the wait")
        XCTAssertEqual(app.textFields["Custom Name"].value as? String, "Regression Marker",
                       "Custom Name entered while editing a freshly-duplicated event must not be "
                       + "silently reset once SwiftData's autosave has had time to run")
    }

    func test_duplicate_keepsOriginalRowIdentity() throws {
        launchApp()

        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should be accessible")
        tab.tap()

        func eventButton(containing substring: String) -> XCUIElement {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
        }

        func beerRows() -> XCUIElementQuery {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "500 ml"))
        }

        let row = eventButton(containing: "500 ml")
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Seeded beer row should be present")
        row.press(forDuration: 1.2)

        let duplicate = app.buttons["Duplicate"]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5), "Context menu should offer Duplicate")
        duplicate.tap()

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if beerRows().count == 2 { break }
            usleep(150_000)
        }
        XCTAssertEqual(beerRows().count, 2,
                       "Duplicating must ADD a row, not replace the original — the original row's "
                       + "identity must survive the duplicate's persistent-identifier flip")

        XCTAssertTrue(beerRows().element(boundBy: 0).isHittable,
                      "The duplicated row must be hittable, not a torn-down placeholder")
        XCTAssertTrue(beerRows().element(boundBy: 1).isHittable,
                      "The original row must still be hittable after the duplicate is inserted")
    }
}
