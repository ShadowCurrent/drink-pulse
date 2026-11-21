import XCTest

/// Today screen on native cards (plan 0046, Task 3). Default seed: one 500 ml 5% beer today
/// = 2.0 std of the 2.0 std WHO daily limit (100 % = Close to Limit).
@MainActor
final class DashboardUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
        ]
        app.launch()
    }

    // MARK: - Title

    func test_title_isToday_withSubtitle() throws {
        launchApp()
        XCTAssertTrue(app.navigationBars[UITestTabs.today].waitForExistence(timeout: 10),
                      "The first tab's navigation bar should be titled Today")
    }

    // MARK: - Hero

    func test_hero_showsPureAlcoholToday_andCloseToLimit() throws {
        launchApp()
        waitForToday()
        let hero = app.descendants(matching: .any)["today.hero"]
        XCTAssertTrue(hero.waitForExistence(timeout: 10), "Hero card should be visible on Today")
        let label = hero.label
        XCTAssertTrue(label.contains("Pure alcohol today"), "Hero eyebrow missing in '\(label)'")
        XCTAssertTrue(label.contains("2.0"), "Hero value should be 2.0 std, got '\(label)'")
        XCTAssertTrue(label.contains("std"), "Hero value should carry the unit, got '\(label)'")
        XCTAssertTrue(label.contains("Close to Limit"), "100 % of the daily limit is Close to Limit, got '\(label)'")
    }

    // MARK: - Tiles

    func test_tiles_showDrinksAndAlcoholFreeTiles() throws {
        launchApp()
        waitForToday()
        let drinks = element(beginningWith: "Drinks")
        XCTAssertTrue(drinks.waitForExistence(timeout: 10), "Drinks tile should be present")
        XCTAssertTrue(drinks.label.contains("1"), "Drinks tile should read 1, got '\(drinks.label)'")
        scrollToFind(element(beginningWith: "Alcohol-Free Streak"))
        XCTAssertTrue(element(beginningWith: "Alcohol-Free Streak").exists, "Streak tile missing")
        XCTAssertTrue(element(beginningWith: "Alcohol-Free This Month").exists, "Month tile missing")
    }

    // MARK: - Guideline Limits

    func test_guidelineLimits_showsThreeRows() throws {
        launchApp()
        waitForToday()
        XCTAssertTrue(app.staticTexts["Guideline Limits"].waitForExistence(timeout: 10),
                      "Guideline Limits card header should be present")
        for row in ["Today", "7 Days", "30 Days"] {
            let gauge = app.descendants(matching: .any).matching(
                NSPredicate(format: "label == %@ AND value CONTAINS %@", row, "percent")
            ).firstMatch
            XCTAssertTrue(gauge.waitForExistence(timeout: 5), "Gauge row \(row) missing")
        }
    }

    // MARK: - Logging a drink updates the visible values

    func test_loggingDrink_updatesVisibleDrinkCount() throws {
        launchApp()
        waitForToday()
        XCTAssertTrue(element(beginningWith: "Drinks").waitForExistence(timeout: 10))
        XCTAssertTrue(element(beginningWith: "Drinks").label.contains("1"))

        logBeer()

        let updated = waitUntil(timeout: 5) { self.element(beginningWith: "Drinks").label.contains("2") }
        XCTAssertTrue(updated, "Drinks tile should rise to 2 after logging another beer, got '\(element(beginningWith: "Drinks").label)'")
    }

    func test_loggingDrink_stillUpdatesProgressViews_afterEntranceAnimationSettles() throws {
        launchApp()
        waitForToday()
        let todayRow = todayGauge()
        XCTAssertTrue(todayRow.waitForExistence(timeout: 10), "Today gauge row should be present")
        let before = todayRow.value as? String ?? ""

        logBeer()

        let changed = waitUntil(timeout: 5) { [before] in
            let now = self.todayGauge().value as? String ?? ""
            return !now.isEmpty && now != before
        }
        XCTAssertTrue(changed, "Today gauge should update after logging (before='\(before)')")
        let hero = app.descendants(matching: .any)["today.hero"]
        XCTAssertTrue(hero.label.contains("4.0"), "Hero should show 4.0 std, got '\(hero.label)'")
    }

    // MARK: - Helpers

    private func logBeer() {
        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add Drink button should be present")
        addButton.tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5))
        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 5))
        beerTile.tap()
        let beerNavBar = app.navigationBars["Beer"]
        XCTAssertTrue(beerNavBar.waitForExistence(timeout: 5))
        beerNavBar.buttons["Save"].tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars[UITestTabs.today].waitForExistence(timeout: 5))
    }

    private func todayGauge() -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@ AND value CONTAINS %@", "Today", "percent")
        ).firstMatch
    }

    private func waitForToday() {
        XCTAssertTrue(app.navigationBars[UITestTabs.today].waitForExistence(timeout: 10),
                      "Today navigation bar should appear after launch")
    }

    private func element(beginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch
    }

    private func scrollToFind(_ element: XCUIElement) {
        var attempts = 0
        while !element.isHittable, attempts < 4 {
            app.swipeUp()
            attempts += 1
        }
    }

    private func waitUntil(timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            usleep(150_000)
        }
        return condition()
    }
}
