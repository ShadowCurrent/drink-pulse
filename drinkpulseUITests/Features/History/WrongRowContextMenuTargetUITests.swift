import XCTest

@MainActor
final class WrongRowContextMenuTargetUITests: XCTestCase {
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
            "-dp_uitest_dataset", "sameday",
        ]
        app.launch()
    }

    private func rows(containing substring: String) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring))
    }

    func test_duplicateBottomRow_duplicatesBeerNotWine() throws {
        launchApp()

        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should be accessible")
        tab.tap()

        let beerRow = rows(containing: "330 ml").firstMatch
        XCTAssertTrue(beerRow.waitForExistence(timeout: 10), "Seeded 330 ml beer row should be present")
        XCTAssertTrue(rows(containing: "750 ml").firstMatch.waitForExistence(timeout: 5), "Seeded wine row should be present")

        beerRow.press(forDuration: 1.2)

        let duplicate = app.buttons["Duplicate"]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5), "Context menu should offer Duplicate")
        duplicate.tap()

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if rows(containing: "330 ml").count == 2 || rows(containing: "750 ml").count == 2 { break }
            usleep(150_000)
        }

        let beerCount = rows(containing: "330 ml").count
        let wineCount = rows(containing: "750 ml").count
        XCTAssertEqual(beerCount, 2,
                       "Long-pressing the BOTTOM (beer) row and tapping Duplicate must duplicate the "
                       + "BEER row (count should be 2), got beer=\(beerCount) wine=\(wineCount)")
        XCTAssertEqual(wineCount, 1,
                       "The wine row (TOP, not pressed) must be unaffected, got wine=\(wineCount)")
    }

    func test_deleteBottomRow_deletesBeerNotWine() throws {
        launchApp()

        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should be accessible")
        tab.tap()

        let beerRow = rows(containing: "330 ml").firstMatch
        XCTAssertTrue(beerRow.waitForExistence(timeout: 10), "Seeded 330 ml beer row should be present")
        XCTAssertTrue(rows(containing: "750 ml").firstMatch.waitForExistence(timeout: 5), "Seeded wine row should be present")

        beerRow.press(forDuration: 1.2)

        let delete = app.buttons["Delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "Context menu should offer Delete")
        delete.tap()

        let confirm = app.buttons["confirmContextDeleteButton"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Delete should open a confirmation")
        confirm.tap()

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if rows(containing: "330 ml").count == 0 || rows(containing: "750 ml").count == 0 { break }
            usleep(150_000)
        }

        XCTAssertEqual(rows(containing: "330 ml").count, 0,
                       "Long-pressing the BOTTOM (beer) row and confirming Delete must delete the BEER row")
        XCTAssertEqual(rows(containing: "750 ml").count, 1,
                       "The wine row (TOP, not pressed) must survive")
    }
}
