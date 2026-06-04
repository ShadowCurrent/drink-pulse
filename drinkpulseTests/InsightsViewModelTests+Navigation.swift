import Testing
import Foundation
@testable import drinkpulse

@MainActor
extension InsightsViewModelTests {

    // MARK: - InsightsPeriod navigation

    @Test func period_navigatePrev_decreasesOffset() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        // Event 14 days back ensures minAllowedOffset ≤ -2
        vm.events = [event(daysAgo: 14, in: c.mainContext)]
        vm.navigatePrev()
        #expect(vm.weekOffset == -1)
    }

    @Test func period_navigateNext_doesNothingAtCurrentPeriod() {
        let vm = makeVM()
        vm.period = .week
        vm.navigateNext()
        #expect(vm.weekOffset == 0)
    }

    @Test func period_jumpToNow_resetsOffset() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        vm.events = [event(daysAgo: 21, in: c.mainContext)]
        vm.navigatePrev()
        vm.navigatePrev()
        vm.jumpToNow()
        #expect(vm.weekOffset == 0)
        #expect(vm.isCurrentPeriod)
    }

    @Test func period_independentOffsets_preservedAcrossScopeSwitch() throws {
        let c = try makeContainer()
        let vm = makeVM()
        // 70 days back is far enough for both -2 weeks and -1 month
        vm.events = [event(daysAgo: 70, in: c.mainContext)]
        vm.period = .week
        vm.navigatePrev()
        vm.navigatePrev()
        vm.period = .month
        vm.navigatePrev()
        vm.period = .week
        #expect(vm.weekOffset == -2)
        #expect(vm.monthOffset == -1)
    }

    @Test func period_cannotNavigateBeyondOldestEvent() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .year
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        vm.now = fmt.date(from: "2026-06-01")!
        // Oldest event is ~1 year back → minAllowedOffset = -1
        vm.events = [event(daysAgo: 365, relativeTo: vm.now, in: c.mainContext)]
        for _ in 0..<10 {
            vm.navigatePrev()
        }
        #expect(vm.yearOffset == -1)
    }

    @Test func period_navigatePrev_blockedWhenNoEvents() {
        let vm = makeVM()
        vm.period = .week
        vm.events = []
        vm.navigatePrev()
        #expect(vm.weekOffset == 0)
    }

    @Test func period_navigateNext_increasesOffset_whenNegative() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        vm.events = [event(daysAgo: 14, in: c.mainContext)]
        vm.navigatePrev()
        vm.navigateNext()
        #expect(vm.weekOffset == 0)
        #expect(vm.isCurrentPeriod)
    }

    // MARK: - minAllowedOffset

    @Test func minAllowedOffset_noEvents_returnsZero() {
        let vm = makeVM()
        vm.events = []
        #expect(vm.minAllowedOffset == 0)
    }

    @Test func minAllowedOffset_eventInCurrentWeek_returnsZero() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        vm.events = [event(daysAgo: 0, in: c.mainContext)]
        #expect(vm.minAllowedOffset == 0)
    }

    @Test func minAllowedOffset_eventOneWeekBack_returnsMinusOne() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        vm.now = fmt.date(from: "2026-06-03")!
        // 9 days ago from 2026-06-03 = 2026-05-25, which is in the previous week
        vm.events = [event(daysAgo: 9, relativeTo: vm.now, in: c.mainContext)]
        #expect(vm.minAllowedOffset == -1)
    }

    // MARK: - friendlyLabel / rangeLabel

    @Test func friendlyLabel_currentAndPrevPeriodDiffer() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        vm.events = [event(daysAgo: 14, in: c.mainContext)]
        let current = vm.friendlyLabel
        vm.navigatePrev()
        let prev = vm.friendlyLabel
        #expect(current != prev)
    }

    @Test func rangeLabel_weekContainsDash() {
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        #expect(vm.rangeLabel.contains("\u{2013}"))
    }

    // MARK: - formattedValue / formattedSpend

    @Test func formattedValue_noProfile_returnsGramsString() {
        let vm = makeVM()
        #expect(vm.formattedValue(42.0) == "42 g")
    }

    @Test func formattedSpend_noProfile_nonEmpty() {
        let vm = makeVM()
        #expect(!vm.formattedSpend(5.0).isEmpty)
    }
}
