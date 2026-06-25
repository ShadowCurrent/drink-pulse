import XCTest

/// Dashboard coverage (plan-0032, step 2).
///
/// Asserts the Home (`DashboardView`) screen renders its sections for the
/// seeded fixture (one 500 ml 5% beer) and that logging another drink updates
/// the visible totals:
/// - the hero arc card shows a "Today's Intake" consumption value reflecting
///   the seeded beer;
/// - the calories / drinks chip row is present and shows the seeded count;
/// - the "Overview" (`ConsumptionOverviewCard`) and "This Week"
///   (`ThisWeekCard`) cards are present;
/// - logging a second beer raises the visible drink count from 1 to 2.
///
/// Locators key off app-rendered ENGLISH text only. Each card combines its
/// children into a single accessibility element with an explicit label, so the
/// hero, chips and overview rows surface as elements whose `label` is the
/// combined string (e.g. "Today's Intake: 2.0 std", "Drinks: 1"). Section
/// headers ("Overview", "This Week") surface as plain `staticTexts`.
///
/// The seeded profile is metric + WHO with the default `.standardDrinks`
/// alcohol unit, so the seeded beer reads `20.0 g` mass → `2.0 std`. Number
/// formatting uses `String(format: "%.1f", …)`, which is locale-independent
/// ("." decimal separator regardless of the Polish system locale), so asserting
/// the "2.0" / "std" substrings is safe. The drink-count assertions
/// ("Drinks: 1" → "Drinks: 2") are plain integers and likewise locale-safe.
@MainActor
final class DashboardUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Builds and launches the app into Home with the deterministic seed.
    /// Kept off the nonisolated `setUpWithError` override so the
    /// MainActor-isolated XCUI calls run on the MainActor.
    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
        ]
        app.launch()
    }

    // MARK: - Hero arc card reflects the seeded beer

    /// The hero card combines into one element labelled "Today's Intake: <value>".
    /// For the seeded 500 ml 5% beer in std-drinks mode that value is "2.0 std".
    func test_heroCard_showsSeededConsumptionValue() throws {
        launchApp()
        waitForHome()

        // Match the combined hero element by its eyebrow prefix, tolerant of the
        // exact formatted value but pinned to the seeded "2.0 std" reading.
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

    /// The calories + drinks chips each combine into a "<label>: <value>" element.
    /// The seed has exactly one event, so the Drinks chip reads "Drinks: 1".
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

    /// Both lower cards must render. "Overview" and "This Week" are their section
    /// headers; the overview's "Today" row combines into a labelled element.
    func test_overviewAndThisWeekCards_arePresent() throws {
        launchApp()
        waitForHome()

        let overviewHeader = app.staticTexts["Overview"]
        XCTAssertTrue(overviewHeader.waitForExistence(timeout: 10),
                      "Overview card header should be present on Home")

        // The overview's Today row combines into "Today: <x> of <y> std, <n> percent".
        let todayRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "Today:")
        ).firstMatch
        XCTAssertTrue(todayRow.waitForExistence(timeout: 5),
                      "Overview card should contain a Today intake row")

        // This Week card lives below; scroll it into view before asserting.
        let thisWeekHeader = app.staticTexts["This Week"]
        if !thisWeekHeader.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(thisWeekHeader.waitForExistence(timeout: 5),
                      "This Week card header should be present on Home")
    }

    // MARK: - Logging a drink updates the visible total

    /// Drives the real Add Drink flow (open → Beer → Save), returns to Home, and
    /// asserts the Drinks chip count rises from the seeded 1 to 2 — proving the
    /// dashboard reflects newly logged consumption.
    func test_loggingDrink_updatesVisibleDrinkCount() throws {
        launchApp()
        waitForHome()

        XCTAssertTrue(app.staticTexts["Drinks: 1"].waitForExistence(timeout: 10),
                      "Drinks chip should start at 'Drinks: 1' before logging")

        // Open Add Drink (toolbar button labelled "Add Drink").
        let addButton = app.buttons["Add Drink"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5),
                      "Add Drink button should be present on Home")
        addButton.tap()
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForExistence(timeout: 5),
                      "Add Drink sheet should be presented")

        // Pick the Beer category tile, then save with the default serving.
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

        // Sheet dismisses back to Home; the chip must now reflect two events.
        XCTAssertTrue(app.navigationBars["Add Drink"].waitForNonExistence(timeout: 5),
                      "Add Drink sheet should dismiss after saving")
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5),
                      "Saving should return to the Home screen")

        XCTAssertTrue(app.staticTexts["Drinks: 2"].waitForExistence(timeout: 5),
                      "Drinks chip should rise to 'Drinks: 2' after logging another beer")
        XCTAssertFalse(app.staticTexts["Drinks: 1"].exists,
                       "The stale 'Drinks: 1' chip should no longer be shown")
    }

    // MARK: - Helpers

    /// Waits for Home to be on screen (its navigation bar) after launch.
    private func waitForHome() {
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 10),
                      "Home screen navigation bar should appear after launch")
    }

    /// Returns the first element whose accessibility label begins with `prefix`
    /// (used for the combined chip elements like "Calories: 142 kcal").
    private func chip(beginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch
    }
}
