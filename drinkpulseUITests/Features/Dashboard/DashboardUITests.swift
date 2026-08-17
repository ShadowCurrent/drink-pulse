import XCTest

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

    // MARK: - Hero arc card reflects the seeded beer

    func test_heroCard_showsSeededConsumptionValue() throws {
        launchApp()
        waitForHome()

        let hero = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "Today's Intake")
        ).firstMatch
        XCTAssertTrue(hero.waitForExistence(timeout: 10),
                      "Hero card with a \"Today's Intake\" label should be visible on Home")

        let heroLabel = hero.label
        XCTAssertTrue(heroLabel.contains("2.0"),
                      "Hero value should reflect the seeded beer (2.0 std), got '\(heroLabel)'")
        XCTAssertTrue(heroLabel.contains("std"),
                      "Hero value should carry the std-drinks unit token, got '\(heroLabel)'")
    }

    // MARK: - Chip row present and shows the seeded count

    func test_chipRow_present_andShowsSeededDrinkCount() throws {
        launchApp()
        waitForHome()

        let caloriesChip = chip(beginningWith: "Calories:")
        XCTAssertTrue(caloriesChip.waitForExistence(timeout: 10),
                      "Calories chip should be present on Home")

        let drinksChip = app.staticTexts["Drinks: 1"]
        XCTAssertTrue(drinksChip.waitForExistence(timeout: 5),
                      "Drinks chip should read 'Drinks: 1' for the single seeded beer")
    }

    // MARK: - Overview + This Week cards present

    func test_overviewAndThisWeekCards_arePresent() throws {
        launchApp()
        waitForHome()

        let overviewHeader = app.staticTexts["Overview"]
        XCTAssertTrue(overviewHeader.waitForExistence(timeout: 10),
                      "Overview card header should be present on Home")

        let todayRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "Today:")
        ).firstMatch
        XCTAssertTrue(todayRow.waitForExistence(timeout: 5),
                      "Overview card should contain a Today intake row")

        let thisWeekHeader = app.staticTexts["This Week"]
        if !thisWeekHeader.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(thisWeekHeader.waitForExistence(timeout: 5),
                      "This Week card header should be present on Home")
    }

    // MARK: - Logging a drink updates the visible total

    func test_loggingDrink_updatesVisibleDrinkCount() throws {
        launchApp()
        waitForHome()

        XCTAssertTrue(app.staticTexts["Drinks: 1"].waitForExistence(timeout: 10),
                      "Drinks chip should start at 'Drinks: 1' before logging")

        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "Add Drink button should be present on Home")
        addButton.tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5),
                      "Add Drink sheet should be presented")

        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 5),
                      "Beer tile should be visible in the Add Drink grid")
        beerTile.tap()

        let beerNavBar = app.navigationBars["Beer"]
        XCTAssertTrue(beerNavBar.waitForExistence(timeout: 5),
                      "Beer detail screen should appear")

        let saveButton = beerNavBar.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5),
                      "Beer detail screen should have a Save button")
        saveButton.tap()

        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5),
                      "Add Drink sheet should dismiss after saving")
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5),
                      "Saving should return to the Home screen")

        XCTAssertTrue(app.staticTexts["Drinks: 2"].waitForExistence(timeout: 5),
                      "Drinks chip should rise to 'Drinks: 2' after logging another beer")
        XCTAssertFalse(app.staticTexts["Drinks: 1"].exists,
                       "The stale 'Drinks: 1' chip should no longer be shown")
    }

    // MARK: - Progress views keep updating after the entrance-animation fix

    func test_loggingDrink_stillUpdatesProgressViews_afterEntranceAnimationSettles() throws {
        launchApp()
        waitForHome()

        let todayRowBefore = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "Today:")
        ).firstMatch
        XCTAssertTrue(todayRowBefore.waitForExistence(timeout: 10),
                      "Overview card should show a Today intake row before logging")
        let beforeLabel = todayRowBefore.label

        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "Add Drink button should be present on Home")
        addButton.tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5),
                      "Add Drink sheet should be presented")

        let beerTile = app.buttons["Beer"]
        XCTAssertTrue(beerTile.waitForExistence(timeout: 5),
                      "Beer tile should be visible in the Add Drink grid")
        beerTile.tap()

        let beerNavBar = app.navigationBars["Beer"]
        XCTAssertTrue(beerNavBar.waitForExistence(timeout: 5),
                      "Beer detail screen should appear")
        let saveButton = beerNavBar.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5),
                      "Beer detail screen should have a Save button")
        saveButton.tap()

        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5),
                      "Saving should return to the Home screen")

        let changed = waitUntil(timeout: 5) { [beforeLabel] in
            let now = self.app.descendants(matching: .any).matching(
                NSPredicate(format: "label BEGINSWITH %@", "Today:")
            ).firstMatch.label
            return !now.isEmpty && now != beforeLabel
        }
        XCTAssertTrue(changed,
                      "Today row should update after logging a second drink "
                      + "(before='\(beforeLabel)')")

        let hero = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "Today's Intake")
        ).firstMatch
        XCTAssertTrue(hero.waitForExistence(timeout: 5),
                      "Hero card should still be present after logging")
        XCTAssertTrue(hero.label.contains("4.0"),
                      "Hero value should reflect two seeded beers (4.0 std), got '\(hero.label)'")
    }

    private func waitUntil(timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            usleep(150_000)
        }
        return condition()
    }

    // MARK: - Helpers

    private func waitForHome() {
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 10),
                      "Home screen navigation bar should appear after launch")
    }

    private func chip(beginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch
    }
}
