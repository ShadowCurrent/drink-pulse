import XCTest

/// Regression coverage for the "future days count as drink-free" bug
/// (quick-260718-vgy, follow-up to quick-260718-kgp's Longest Streak fix).
/// Split out of `InsightsUITests` to keep that file under the 300-line
/// ceiling; reuses the same `-dp_uitest_dataset multiday` fixture and
/// locator conventions (English a11y text only — the simulator's system
/// locale may not be English, but the app's own strings always are).
@MainActor
final class InsightsDrinkFreeDaysUITests: XCTestCase {
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

    // MARK: - Month view Drink-Free Days excludes future days

    /// Regression for the "future days count as drink-free" bug: the Month
    /// scope's "Drink-Free Days" card must count only elapsed days of the
    /// month (up to and including today) in BOTH the numerator (free) and
    /// the denominator (total), never the not-yet-happened rest of the
    /// month. Computes the expected elapsed-only (free, total) in-process
    /// from the known multi-day seed (drinking days at day-offsets
    /// 0,1,2,4,6,7,9,11,13 before launch day) and asserts it matches the
    /// value the app actually renders.
    func test_monthView_drinkFreeDays_excludesFutureDays() throws {
        launchApp()
        openInsights()

        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10),
                      "Period segmented control should be present on Insights")
        let monthButton = picker.buttons["Month"]
        XCTAssertTrue(monthButton.waitForExistence(timeout: 5),
                      "Period picker should offer a 'Month' segment")
        monthButton.tap()

        let cell = firstElement(beginningWith: "Drink-Free Days")
        XCTAssertTrue(cell.waitForExistence(timeout: 10),
                      "Health metrics should include a 'Drink-Free Days' cell")

        // Label is exactly "Drink-Free Days: X/Y".
        let label = cell.label
        let parts = label.components(separatedBy: "/")
        XCTAssertEqual(parts.count, 2, "Expected an 'X/Y' value in label '\(label)'")

        let freeDigits = parts[0].filter(\.isNumber)
        let totalDigits = parts.count > 1 ? parts[1].filter(\.isNumber) : ""
        let actualFree = Int(freeDigits)
        let actualTotal = Int(totalDigits)
        XCTAssertNotNil(actualFree, "Could not parse a free-days value out of '\(label)'")
        XCTAssertNotNil(actualTotal, "Could not parse a total-days value out of '\(label)'")

        let expected = Self.expectedElapsedOnlyDrinkFreeDays()
        XCTAssertEqual(
            actualFree, expected.free,
            "Month-view Drink-Free numerator should equal the elapsed-only computation "
            + "(\(expected.free)); label was '\(label)'."
        )
        XCTAssertEqual(
            actualTotal, expected.total,
            "Month-view Drink-Free denominator should equal the elapsed-only computation "
            + "(\(expected.total)); a larger denominator ('\(label)') means the "
            + "(now-fixed) future-day counting has regressed."
        )
    }

    /// Mirrors production `elapsedDays` + `drinkFreeDays`: walks the current
    /// month from its start through today (inclusive) using the known
    /// multi-day seed's drinking-day offsets, incrementing `total` every day
    /// and `free` when the day is not a drinking day.
    private static func expectedElapsedOnlyDrinkFreeDays() -> (free: Int, total: Int) {
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        guard let monthStart = cal.dateInterval(of: .month, for: today)?.start else { return (0, 0) }

        let drinkingOffsets = [0, 1, 2, 4, 6, 7, 9, 11, 13]
        let drinkingDays = Set(
            drinkingOffsets
                .compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
                .filter { $0 >= monthStart }
        )

        var total = 0
        var free = 0
        var day = monthStart
        while day <= today {
            total += 1
            if !drinkingDays.contains(day) { free += 1 }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return (free, total)
    }
}
