import XCTest
@testable import drinkpulse

/// Synchronous compute-cost profiling for the three data-heavy screens with a
/// large dataset (1000 events spread over ~2 years). The view models are
/// `@Observable @MainActor` and stateless w.r.t. persistence — they receive a
/// plain `[ConsumptionEvent]` and derive everything on the fly, so feeding them
/// 1000 events here measures exactly the work a real screen does on `body`
/// evaluation. `measure {}` runs 10 iterations and reports the average wall time.
///
/// These are not pass/fail correctness tests; they exist to catch the lag the
/// user asked about (entering a tab with a big history) and to give a baseline
/// to compare future changes against. Read the times in the test report.
@MainActor
final class ScreenComputePerformanceTests: XCTestCase {
    /// 1000 events across ~730 days: ~1.4/day with gaps, varied volume/ABV and a
    /// price on every other one, so spend/binge/streak paths are all exercised.
    private func makeEvents(count: Int = 1000) -> [ConsumptionEvent] {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -730, to: .now) ?? .now
        return (0..<count).map { i in
            let dayOffset = (i * 730) / count
            let hour = 18 + (i % 5)
            let base = cal.date(byAdding: .day, value: dayOffset, to: start) ?? start
            let ts = cal.date(byAdding: .hour, value: hour, to: cal.startOfDay(for: base)) ?? base
            return ConsumptionEvent(
                timestamp: ts,
                volumeMl: Double(300 + (i % 4) * 100),
                abv: [0.05, 0.12, 0.40, 0.08][i % 4],
                quantity: 1 + (i % 2),
                name: "Drink",
                category: [.beer, .wine, .spirits, .cider][i % 4],
                icon: "🍺",
                price: i % 2 == 0 ? 4.5 : nil
            )
        }
    }

    private var profile: UserProfile { UserProfile.preview }

    // MARK: - Dashboard

    /// Reads every aggregate the Dashboard view actually renders (today / 7-day /
    /// 30-day / weekly totals, week bar chart, streak, sober days, calories).
    func test_dashboard_compute_1000events() {
        let events = makeEvents()
        measure {
            let vm = DashboardViewModel()
            vm.events = events
            vm.profile = profile
            _ = vm.todayGrams
            _ = vm.sevenDayGrams
            _ = vm.thirtyDayGrams
            _ = vm.weeklyGrams
            _ = vm.weekBarData
            _ = vm.currentStreakDays
            _ = vm.soberDaysThisMonthDates
            _ = vm.todayCaloriesKcal
            _ = vm.todayDrinkCount
            _ = vm.todaySpend
        }
    }

    // MARK: - Insights (all-time = worst case, touches all 1000)

    func test_insights_compute_1000events_allTime() {
        let events = makeEvents()
        measure {
            let vm = InsightsViewModel()
            vm.period = .allTime
            vm.events = events
            vm.profile = profile
            _ = vm.periodTotalGrams
            _ = vm.prevPeriodTotalGrams
            _ = vm.trendFraction
            _ = vm.bingeEpisodes
            _ = vm.periodCaloriesKcal
            _ = vm.drinkFreeDays
            _ = vm.longestSoberStreak
            _ = vm.heaviestDay
            _ = vm.periodSpend
            _ = vm.guidelineComparisons
            _ = vm.activeDays
        }
    }

    // MARK: - History

    /// History windows its List, but the calendar builds a full month grid and
    /// the day grouping runs over the visible window. Measure both heavy paths.
    func test_history_compute_1000events() {
        let events = makeEvents()
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        measure {
            let vm = HistoryViewModel()
            _ = vm.groupedByDay(events, calendar: cal)
            _ = vm.gramsByDay(events, density: 0.8, calendar: cal)
            _ = vm.monthCells(
                year: comps.year ?? 2026,
                month: comps.month ?? 1,
                events: events,
                density: 0.8,
                calendar: cal,
                today: .now
            )
        }
    }
}
