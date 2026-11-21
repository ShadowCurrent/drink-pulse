import XCTest

/// Native row actions on History (plan 0045, Task 3, D0045-4 / D0045-5): leading swipe
/// Log Again (no full swipe), trailing swipe Delete (full swipe, no dialog), context-menu
/// Delete still confirmed.
@MainActor
final class HistorySwipeActionsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(healthWrite: Bool = false) {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_unit", "metric",
        ]
        if healthWrite {
            app.launchArguments += ["-dp_health_write_enabled", "YES"]
        }
        app.launch()
    }

    private func openHistoryTab() {
        let tab = app.tabBars.buttons["History"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "History tab should exist")
        tab.tap()
    }

    private func row(containing substring: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
    }

    private func rowCount(containing substring: String) -> Int {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", substring)).count
    }

    private func waitForRowCount(_ substring: String, _ expected: Int, timeout: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if rowCount(containing: substring) == expected { return true }
            usleep(150_000)
        }
        return rowCount(containing: substring) == expected
    }

    private var healthSampleProbe: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "dp_health_sample_count").firstMatch
    }

    private func waitForProbe(_ expected: String, timeout: TimeInterval = 10) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if healthSampleProbe.label == expected { return true }
            usleep(150_000)
        }
        return healthSampleProbe.label == expected
    }

    /// A long drag across most of the row: the system's full swipe.
    private func fullSwipe(_ element: XCUIElement, toTrailing: Bool) {
        let from = element.coordinate(withNormalizedOffset: CGVector(dx: toTrailing ? 0.1 : 0.9, dy: 0.5))
        let to = element.coordinate(withNormalizedOffset: CGVector(dx: toTrailing ? 1.4 : -0.4, dy: 0.5))
        from.press(forDuration: 0.05, thenDragTo: to)
    }

    func test_leadingSwipe_logAgain_addsRowNow() throws {
        launchApp()
        openHistoryTab()
        let beer = row(containing: "500 ml")
        XCTAssertTrue(beer.waitForExistence(timeout: 10), "Seeded 500 ml beer row should exist")
        XCTAssertEqual(rowCount(containing: "500 ml"), 1)

        beer.swipeRight()
        let logAgain = app.buttons["history.row.logAgain"]
        XCTAssertTrue(logAgain.waitForExistence(timeout: 5), "Leading swipe should reveal Log Again")
        logAgain.tap()

        XCTAssertTrue(waitForRowCount("500 ml", 2), "Log Again should add a second 500 ml row")
    }

    func test_leadingFullSwipe_doesNotLogAgain() throws {
        launchApp()
        openHistoryTab()
        let beer = row(containing: "500 ml")
        XCTAssertTrue(beer.waitForExistence(timeout: 10), "Seeded 500 ml beer row should exist")

        fullSwipe(beer, toTrailing: true)
        sleep(1)
        XCTAssertEqual(rowCount(containing: "500 ml"), 1,
                       "A full leading swipe must not log a drink by accident")
    }

    func test_trailingFullSwipe_deletesWithoutDialog() throws {
        launchApp()
        openHistoryTab()
        let beer = row(containing: "500 ml")
        XCTAssertTrue(beer.waitForExistence(timeout: 10), "Seeded 500 ml beer row should exist")

        fullSwipe(beer, toTrailing: false)

        XCTAssertTrue(waitForRowCount("500 ml", 0), "A full trailing swipe should delete the row")
        XCTAssertFalse(app.buttons["confirmContextDeleteButton"].exists,
                       "Swipe delete must not ask for confirmation")
    }

    /// Review focus 2: deleting by swipe also removes the Apple Health sample.
    func test_trailingSwipe_deleteRemovesHealthSample() throws {
        launchApp(healthWrite: true)
        XCTAssertTrue(healthSampleProbe.waitForExistence(timeout: 10), "Health probe should exist")

        let add = app.buttons["Add Drink"]
        XCTAssertTrue(add.waitForExistence(timeout: 10), "Add Drink should exist")
        add.tap()
        let wine = app.buttons["Wine"]
        XCTAssertTrue(wine.waitForExistence(timeout: 10), "Wine tile should exist")
        wine.tap()
        let name = app.textFields["Custom Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5), "Custom Name field should exist")
        name.tap()
        name.typeText("Swipe Wine")
        let save = app.navigationBars["Wine"].buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5), "Save should exist")
        save.tap()
        XCTAssertTrue(waitForProbe("1"), "Logging with Health on should write one sample")

        openHistoryTab()
        let wineRow = row(containing: "Swipe Wine")
        XCTAssertTrue(wineRow.waitForExistence(timeout: 10), "Logged wine should appear in History")
        wineRow.swipeLeft()
        let delete = app.buttons["history.row.delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "Trailing swipe should reveal Delete")
        delete.tap()

        XCTAssertTrue(waitForRowCount("Swipe Wine", 0), "Swipe Delete should remove the wine row")
        XCTAssertTrue(waitForProbe("0"), "Swipe Delete must remove the Health sample")
    }

    func test_contextMenuDelete_stillAsksForConfirmation() throws {
        launchApp()
        openHistoryTab()
        let beer = row(containing: "500 ml")
        XCTAssertTrue(beer.waitForExistence(timeout: 10), "Seeded 500 ml beer row should exist")
        beer.press(forDuration: 1.2)

        XCTAssertTrue(app.buttons["Log Again"].waitForExistence(timeout: 5),
                      "Context menu should offer Log Again")
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.buttons["confirmContextDeleteButton"].firstMatch.waitForExistence(timeout: 5),
                      "Context-menu Delete should still ask for confirmation")
        XCTAssertEqual(rowCount(containing: "500 ml"), 1, "Nothing is deleted before confirming")
    }
}
