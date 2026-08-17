import XCTest

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

    // MARK: - Month view Drink-Free Days excludes future days

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
