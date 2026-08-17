import XCTest

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

    private func openInsights() {
        let insightsTab = app.tabBars.buttons["Insights"]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 10),
                      "Insights tab button should be visible after launch")
        insightsTab.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5),
                      "Insights screen navigation bar should appear")
    }

    private func firstElement(beginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch
    }

    // MARK: - Month view Longest Streak excludes future days

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
