import XCTest

/// Regression coverage for the "future days count as sober" Longest Streak bug
/// (quick-260718-kgp). Split out of `InsightsUITests` to keep that file under
/// the 300-line ceiling; reuses the same `-dp_uitest_dataset multiday` fixture
/// and locator conventions (English a11y text only — the simulator's system
/// locale may not be English, but the app's own strings always are).
@MainActor
final class InsightsStreakUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += [
            "-dp_onboarding_done", "YES",
            "-dp_uitest", "YES",
            "-dp_uitest_dataset", "multiday",
        ]
        app.launch()
    }

    /// Opens the Insights tab and waits for its navigation bar.
    private func openInsights() {
        let insightsTab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 10),
                      "Insights tab button should be visible after launch")
        insightsTab.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5),
                      "Insights screen navigation bar should appear")
    }

    /// First element (any type) whose accessibility label begins with `prefix`.
    private func firstElement(beginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch
    }

    // MARK: - Month view Longest Streak excludes future days

    /// Regression for the "future days count as sober" bug: the Month scope's
    /// "Longest Streak" card must count only elapsed days of the month (up to
    /// and including today), never the not-yet-happened rest of the month.
    /// Computes the expected elapsed-only streak in-process from the known
    /// multi-day seed (drinking days at day-offsets 0,1,2,4,6,7,9,11,13 before
    /// launch day) and asserts it matches the value the app actually renders.
    func test_monthView_longestStreak_excludesFutureDays() throws {
        launchApp()
        openInsights()

        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10),
                      "Period segmented control should be present on Insights")
        let monthButton = picker.buttons["Month"]
        XCTAssertTrue(monthButton.waitForExistence(timeout: 5),
                      "Period picker should offer a 'Month' segment")
        monthButton.tap()

        let streakCell = firstElement(beginningWith: "Longest Streak")
        XCTAssertTrue(streakCell.waitForExistence(timeout: 10),
                      "Health metrics should include a 'Longest Streak' cell")

        let label = streakCell.label
        let digits = label.filter(\.isNumber)
        XCTAssertFalse(digits.isEmpty,
                       "Could not parse a streak value out of '\(label)'")
        let actual = Int(digits)
        XCTAssertNotNil(actual, "Could not parse a streak value out of '\(label)'")

        let expected = Self.expectedElapsedOnlyStreak()
        XCTAssertEqual(
            actual, expected,
            "Month-view Longest Streak should equal the elapsed-only computation "
            + "(\(expected)); a larger value ('\(label)') means future days are "
            + "being counted as sober again."
        )
    }

    /// Mirrors production `elapsedDays` + `longestSoberStreak`: walks the
    /// current month from its start through today (inclusive) using the known
    /// multi-day seed's drinking-day offsets, resetting the run on a drinking
    /// day and otherwise incrementing it, tracking the max.
    private static func expectedElapsedOnlyStreak() -> Int {
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        guard let monthStart = cal.dateInterval(of: .month, for: today)?.start else { return 0 }

        let drinkingOffsets = [0, 1, 2, 4, 6, 7, 9, 11, 13]
        let drinkingDays = Set(drinkingOffsets.compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        })

        var best = 0
        var run = 0
        var day = monthStart
        while day <= today {
            if drinkingDays.contains(day) { run = 0 } else { run += 1; best = max(best, run) }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return best
    }
}
