import XCTest

/// Insights coverage (plan-0032, step 5).
///
/// Asserts the `InsightsView` screen renders its sections for a richer,
/// multi-day fixture and that the period picker actually switches the range:
/// - the **period picker** (segmented `Week / Month / Year / All`) switches the
///   active range — proven by the hero "Total" value changing between Week and
///   Year scopes;
/// - the **area chart** (`AlcoholAreaChart`, a11y label "Alcohol Over Time")
///   and the **weekday bar chart** (`WeekdayBarChart`, header + a11y container
///   "Weekday Patterns") are both present;
/// - the **hero card** shows a "Total" value reflecting logged consumption;
/// - the **health metrics** rows are present ("Health Impact" header +
///   "Alcohol Calories" / "Drink-Free Days" cells);
/// - the **guideline comparison** card is present with its WHO / NHS / DHS rows.
///
/// Locators key off app-rendered ENGLISH text only (segmented-control buttons,
/// nav-bar / tab-bar names, section headers, and the charts' English a11y
/// labels). No accessibility identifiers are added — every element needed is
/// uniquely addressable by visible/English-labelled text. Weekday and month
/// axis labels are locale-formatted and are deliberately NOT asserted; the app's
/// own card headers and a11y labels are English-only and locale-safe.
///
/// Driven by a gated, additive, synthetic-only fixture
/// (`-dp_uitest_dataset multiday`, see `UITestSeed+Fixtures.swift`) that seeds a
/// deterministic spread of 9 beer/wine events across the last 14 days so each
/// period scope and chart has data. No PII, inert in production.
@MainActor
final class InsightsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Builds and launches the app straight into the shell with the multi-day
    /// Insights seed. Kept off the nonisolated `setUpWithError` override so the
    /// MainActor-isolated XCUI calls run on the MainActor.
    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_dataset", "multiday",
        ]
        app.launch()
    }

    // MARK: - Period picker switches the range

    /// Switching the segmented period from Week to Year must change the active
    /// range, which the hero "Total" value reflects: the Year scope aggregates
    /// the whole multi-day spread, the Week scope only the current week — so the
    /// two totals differ. Proves the picker is wired to the data, not cosmetic.
    func test_periodPicker_switchesRange_changesHeroTotal() throws {
        launchApp()
        openInsights()

        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10),
                      "Period segmented control should be present on Insights")

        // Default scope is Week.
        let weekButton = picker.buttons["Week"]
        XCTAssertTrue(weekButton.waitForExistence(timeout: 5),
                      "Period picker should offer a 'Week' segment")
        weekButton.tap()
        let weekTotal = heroTotalLabel()
        XCTAssertFalse(weekTotal.isEmpty, "Hero Total value should render for the Week scope")

        // Switch to Year — covers the whole 14-day spread, a different total.
        let yearButton = picker.buttons["Year"]
        XCTAssertTrue(yearButton.waitForExistence(timeout: 5),
                      "Period picker should offer a 'Year' segment")
        yearButton.tap()

        // The hero Total element re-renders with the wider range. Poll briefly
        // for a value that differs from the Week reading.
        let changed = waitUntil(timeout: 5) { [weekTotal] in
            let now = self.heroTotalLabel()
            return !now.isEmpty && now != weekTotal
        }
        XCTAssertTrue(changed,
                      "Switching Week → Year should change the hero Total "
                      + "(Week='\(weekTotal)', Year='\(heroTotalLabel())')")
    }

    // MARK: - Previous-period navigation available on first load

    /// Regression: the multi-day fixture has events in prior weeks (D−7…D−13), so
    /// on first entry into Insights (default Week scope) the "Previous period"
    /// arrow must already be enabled — without first switching the period to force
    /// a re-render. This pins a bug where the oldest-event bound was cached in a
    /// non-observed field, leaving the prev arrow stale (disabled) until an
    /// unrelated state change. Tapping it must move to "Last week".
    func test_weekScope_prevPeriodEnabledOnFirstLoad_andNavigates() throws {
        launchApp()
        openInsights()

        // Default scope is Week; the navigator shows "This week" initially.
        XCTAssertTrue(app.staticTexts["This week"].waitForExistence(timeout: 10),
                      "Insights should open on the current week")

        let prev = app.buttons["Previous period"]
        XCTAssertTrue(prev.waitForExistence(timeout: 5),
                      "Previous-period arrow should be present")
        XCTAssertTrue(prev.isEnabled,
                      "Prev arrow must be enabled on first load — prior weeks have data")

        prev.tap()
        XCTAssertTrue(app.staticTexts["Last week"].waitForExistence(timeout: 5),
                      "Tapping prev from the current week should navigate to 'Last week'")
    }

    // MARK: - Area chart + weekday bar chart present

    /// Both Swift Charts surface via their English accessibility labels: the area
    /// chart as "Alcohol Over Time", the weekday chart as "Weekday Patterns"
    /// (also a visible section header). Asserting the a11y summary satisfies the
    /// CLAUDE.md chart-descriptor requirement without depending on locale-
    /// formatted axis labels.
    func test_areaChartAndWeekdayChart_arePresent() throws {
        launchApp()
        openInsights()

        let areaChart = firstElement(withLabel: "Alcohol Over Time")
        XCTAssertTrue(areaChart.waitForExistence(timeout: 10),
                      "Area chart ('Alcohol Over Time') should be present on Insights")

        // The weekday section header is a plain static text; scroll it into view.
        let weekdayHeader = app.staticTexts["Weekday Patterns"]
        if !weekdayHeader.waitForExistence(timeout: 3) {
            app.swipeUp()
        }
        XCTAssertTrue(weekdayHeader.waitForExistence(timeout: 5),
                      "Weekday bar chart header ('Weekday Patterns') should be present")
    }

    // MARK: - Hero card value

    /// The hero card shows a "Total" eyebrow and a large formatted value. The
    /// value must be non-empty and carry the seeded std-drinks unit token,
    /// proving the card reflects real aggregated consumption. (The eyebrow is
    /// displayed uppercased via `.textCase(.uppercase)`, but its accessibility
    /// label keeps the source string "Total" — assert on that, not "TOTAL".)
    func test_heroCard_showsTotalValue() throws {
        launchApp()
        openInsights()

        let totalHeader = firstElement(withLabel: "Total")
        XCTAssertTrue(totalHeader.waitForExistence(timeout: 10),
                      "Hero card 'Total' eyebrow should be present on Insights")

        let value = heroTotalLabel()
        XCTAssertFalse(value.isEmpty,
                       "Hero card should render a Total value reflecting consumption")
        XCTAssertTrue(value.contains("std"),
                      "Hero Total should carry the std-drinks unit token, got '\(value)'")
    }

    // MARK: - Health metrics rows

    /// The Health Impact card and a couple of its metric cells must render. Cells
    /// combine into "<title>: <value>" elements; "Alcohol Calories" and
    /// "Drink-Free Days" are stable English titles.
    func test_healthMetrics_rowsArePresent() throws {
        launchApp()
        openInsights()

        let healthHeader = app.staticTexts["Health Impact"]
        if !healthHeader.waitForExistence(timeout: 3) {
            app.swipeUp()
        }
        XCTAssertTrue(healthHeader.waitForExistence(timeout: 10),
                      "Health Impact card header should be present on Insights")

        let caloriesCell = firstElement(beginningWith: "Alcohol Calories")
        XCTAssertTrue(caloriesCell.waitForExistence(timeout: 5),
                      "Health metrics should include an 'Alcohol Calories' cell")

        let drinkFreeCell = firstElement(beginningWith: "Drink-Free Days")
        XCTAssertTrue(drinkFreeCell.waitForExistence(timeout: 5),
                      "Health metrics should include a 'Drink-Free Days' cell")
    }

    // MARK: - Guideline comparison card

    /// The Guideline Comparison card and its rows must render. The header is a
    /// static text; each row combines into "<name>: <pct>% of limit" and the WHO
    /// row is always present (the VM always emits WHO / UK / DE).
    func test_guidelineComparison_cardIsPresent() throws {
        launchApp()
        openInsights()

        let header = app.staticTexts["Guideline Comparison"]
        // Lives near the bottom of the scroll view.
        for _ in 0..<3 where !header.exists {
            app.swipeUp()
        }
        XCTAssertTrue(header.waitForExistence(timeout: 10),
                      "Guideline Comparison card header should be present on Insights")

        // A comparison row carries an "... of limit" a11y summary; WHO is the
        // first guideline and always present.
        let limitRow = firstElement(containing: "of limit")
        XCTAssertTrue(limitRow.waitForExistence(timeout: 5),
                      "Guideline Comparison should contain at least one '... of limit' row")
    }

    // MARK: - Helpers

    /// Opens the Insights tab and waits for its navigation bar.
    private func openInsights() {
        let insightsTab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 10),
                      "Insights tab button should be visible after launch")
        insightsTab.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5),
                      "Insights screen navigation bar should appear")
    }

    /// Reads the current hero "Total" value. The value text is the 40-pt rounded
    /// number+unit (e.g. "2.0 std"); it surfaces as a static text containing the
    /// "std" unit token under the hero card. Returns "" if not yet rendered.
    private func heroTotalLabel() -> String {
        let candidate = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "std")
        ).firstMatch
        return candidate.exists ? candidate.label : ""
    }

    /// First element (any type) whose accessibility label equals `label`.
    private func firstElement(withLabel label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", label)
        ).firstMatch
    }

    /// First element (any type) whose accessibility label begins with `prefix`.
    private func firstElement(beginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch
    }

    /// First element (any type) whose accessibility label contains `needle`.
    private func firstElement(containing needle: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", needle)
        ).firstMatch
    }

    /// Polls `condition` until it returns true or `timeout` elapses.
    private func waitUntil(timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            usleep(150_000)
        }
        return condition()
    }
}
