import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// Today's alcohol-free figures follow the shared `AlcoholFreeDayRule` (plan 0050).
@MainActor
extension DashboardViewModelTests {

    private func pinnedVM() -> DashboardViewModel {
        let vm = DashboardViewModel()
        vm.calendar = .current
        vm.now = Self.nov26Morning
        return vm
    }

    /// Old code walked back 366 days because 0 % drinks never break the streak.
    @Test func currentStreak_zeroPercentOnlyYesterday_isOne() throws {
        let c = try makeContainer()
        let vm = pinnedVM()
        vm.events = [event(daysAgo: 1, grams: 0, relativeTo: Self.nov26Morning, in: c.mainContext)]
        #expect(vm.currentStreakDays == 1)
    }

    @Test func currentStreak_stopsAtFirstLogDay() throws {
        let c = try makeContainer()
        let vm = pinnedVM()
        vm.events = [event(daysAgo: 5, grams: 0, relativeTo: Self.nov26Morning, in: c.mainContext)]
        #expect(vm.currentStreakDays == 5)
    }

    @Test func soberDaysThisMonth_excludesTodayWithoutAlcohol() throws {
        let c = try makeContainer()
        let vm = pinnedVM()
        vm.events = [
            event(daysAgo: 3, grams: 0, relativeTo: Self.nov26Morning, in: c.mainContext),
            event(daysAgo: 0, grams: 0, relativeTo: Self.nov26Morning, in: c.mainContext),
        ]
        #expect(vm.soberDaysThisMonth == 3)
    }
}
