import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// Chart slot identity (plan 0046, D0046-9): every series point carries its 0-based index in the
/// period, so the area chart morphs between periods instead of cross-fading.
@MainActor
extension InsightsViewModelTests {

    private func pinned(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func test_seriesSlots_week_areZeroToSix() {
        let vm = makeVM()
        vm.period = .week
        vm.now = pinned(2026, 6, 17)
        vm.events = []
        #expect(vm.seriesData.map(\.slot) == Array(0..<7))
    }

    @Test func test_seriesSlots_month_matchDayCount() {
        let vm = makeVM()
        vm.period = .month
        vm.now = pinned(2028, 2, 10)
        vm.events = []
        #expect(vm.seriesData.map(\.slot) == Array(0..<29))
    }

    @Test func test_seriesSlots_year_areZeroToEleven() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .year
        let now = pinned(2026, 6, 15)
        vm.now = now
        vm.events = [event(daysAgo: 400, grams: 10, relativeTo: now, in: c.mainContext)]
        vm.navigatePrev()
        #expect(vm.seriesData.map(\.slot) == Array(0..<12))
    }

    @Test func test_seriesSlots_emptyRange_stillHaveSlots() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        let now = pinned(2026, 6, 17)
        vm.now = now
        vm.events = [event(daysAgo: 21, grams: 30, relativeTo: now, in: c.mainContext)]
        vm.navigatePrev()
        #expect(vm.seriesData.map(\.slot) == Array(0..<7))
        #expect(vm.seriesData.allSatisfy { $0.grams == 0 })
    }

    @Test func test_chartPoint_id_isSlot() {
        let point = ChartPoint(slot: 3, date: .now, grams: 1)
        #expect(point.id == 3)
    }
}
