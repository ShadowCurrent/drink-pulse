import XCTest
@testable import drinkpulse

@MainActor
final class ScreenComputePerformanceTests: XCTestCase {
    private func makeEvents(count: Int = 1000) -> [ConsumptionEvent] {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -730, to: .now) ?? .now
        return (0..<count).map { i in
            let dayOffset = (i * 730) / count
            let hour = 18 + (i % 5)
            let base = cal.date(byAdding: .day, value: dayOffset, to: start) ?? start
            let ts = cal.date(byAdding: .hour, value: hour, to: cal.startOfDay(for: base)) ?? base
            return ConsumptionEvent(
                consumptionDate: ts,
                volumeMl: Double(300 + (i % 4) * 100),
                abv: [0.05, 0.12, 0.40, 0.08][i % 4],
                quantity: 1 + (i % 2),
                category: [.beer, .wine, .spirits, .cider][i % 4],
                icon: "🍺",
                price: i % 2 == 0 ? 4.5 : nil
            )
        }
    }

    private var profile: UserProfile { UserProfile.preview }

    // MARK: - Dashboard

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

    func test_history_compute_1000events() {
        let events = makeEvents()
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        measure {
            let vm = HistoryViewModel()
            _ = vm.daySections(events, calendar: cal)
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
