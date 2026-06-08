import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
extension InsightsViewModelTests {

    // MARK: - seriesData

    @Test func seriesData_weekPeriodHasSevenPoints() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.seriesData.count == 7)
    }

    @Test func seriesData_emptyGramsWhenNoEvents_week() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.seriesData.allSatisfy { $0.grams == 0 })
    }

    @Test func seriesData_todayGramsReflectEvents_week() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        vm.events = [event(daysAgo: 0, grams: 40, in: c.mainContext)]
        let today = Calendar.current.startOfDay(for: Date.now)
        let todayPoint = vm.seriesData.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        #expect(todayPoint != nil)
        #expect(abs((todayPoint?.grams ?? 0) - 40) < 0.01)
    }

    @Test func seriesData_yearPeriodHasTwelveMonthlyPoints() {
        let vm = makeVM()
        vm.period = .year
        vm.now = .now
        vm.events = []
        #expect(vm.seriesData.count == 12)
    }

    // MARK: - guidelineComparisons

    @Test func guidelineComparisons_alwaysThreeRows() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        #expect(vm.guidelineComparisons.count == 3)
    }

    @Test func guidelineComparisons_includesWHO_NHS_DHS() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        let guidelines = vm.guidelineComparisons.map(\.guideline)
        #expect(guidelines.contains(.who))
        #expect(guidelines.contains(.uk))
        #expect(guidelines.contains(.de))
    }

    @Test func guidelineComparisons_fractionZeroWhenNoEvents() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        #expect(vm.guidelineComparisons.allSatisfy { $0.fraction == 0 })
    }

    // MARK: - monthCaloriesKcal

    @Test func monthCaloriesKcal_zeroWithNoEvents() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        #expect(vm.monthCaloriesKcal == 0)
    }

    @Test func monthCaloriesKcal_correctCalculation() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.now = .now
        // 100 g pure alcohol x 7 kcal/g = 700 kcal
        vm.events = [event(daysAgo: 0, grams: 100, in: c.mainContext)]
        #expect(vm.monthCaloriesKcal == 700)
    }

    // MARK: - monthSpend

    @Test func monthSpend_nilWhenNoEvents() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        #expect(vm.monthSpend == nil)
    }

    @Test func monthSpend_nilWhenNoPrices() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.now = .now
        vm.events = [event(daysAgo: 0, grams: 20, in: c.mainContext)]
        #expect(vm.monthSpend == nil)
    }

    @Test func monthSpend_sumsAllPricesInActivePeriod() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .month
        // Pin to mid-month (2026-05-15, Friday) so daysAgo:1 (May 14) stays in May.
        let pinned = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 15))!
        vm.now = pinned
        vm.events = [
            event(daysAgo: 0, grams: 20, price: 5.0, relativeTo: pinned, in: c.mainContext),
            event(daysAgo: 1, grams: 20, price: 3.5, relativeTo: pinned, in: c.mainContext),
        ]
        #expect(abs((vm.monthSpend ?? 0) - 8.5) < 0.01)
    }

    // MARK: - drinkFreeDays

    @Test func drinkFreeDays_allFreeWhenNoEvents() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        vm.period = .week
        let (free, total) = vm.drinkFreeDays
        #expect(total == 7)
        #expect(free == total)
    }

    @Test func drinkFreeDays_oneDrinkingDay() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        vm.events = [event(daysAgo: 0, grams: 30, in: c.mainContext)]
        let (free, total) = vm.drinkFreeDays
        #expect(total == 7)
        #expect(free == 6)
    }

    // MARK: - longestSoberStreak

    @Test func longestSoberStreak_fullWeekWhenNoEvents() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.longestSoberStreak == 7)
    }

    @Test func longestSoberStreak_reducedWhenHasDrinkingDay() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        vm.events = [event(daysAgo: 0, grams: 30, in: c.mainContext)]
        #expect(vm.longestSoberStreak < 7)
    }

    // MARK: - heaviestDay

    @Test func heaviestDay_nilWhenNoEvents() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.heaviestDay == nil)
    }

    @Test func heaviestDay_returnsMaxGrams() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        vm.events = [event(daysAgo: 0, grams: 50, in: c.mainContext)]
        let h = vm.heaviestDay
        #expect(h != nil)
        #expect(abs((h?.grams ?? 0) - 50) < 0.01)
    }

    // MARK: - prevPeriodTotalGrams / trendFraction

    @Test func prevPeriodTotalGrams_zeroWhenNoEvents() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.prevPeriodTotalGrams == 0)
    }

    @Test func trendFraction_zeroWhenNoPrevData() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.trendFraction == 0)
    }

    // MARK: - periodSpendPerDay

    @Test func periodSpendPerDay_nilWhenNoEvents() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        #expect(vm.periodSpendPerDay == nil)
    }

    @Test func periodSpendPerDay_dividesSpendByDayCount() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        vm.events = [event(daysAgo: 0, grams: 20, price: 7.0, in: c.mainContext)]
        let perDay = vm.periodSpendPerDay
        #expect(perDay != nil)
        // 7.0 total / 7 days in the week = 1.0
        #expect(abs((perDay ?? 0) - 1.0) < 0.01)
    }

    // MARK: - limits(for: .custom)

    @Test func limits_custom_usesDefaultWeeklyGoalWhenNoProfile() {
        let vm = makeVM()
        // profile = nil -> weeklyGoalGrams ?? 100
        let l = vm.limits(for: .custom)
        #expect(abs(l.weeklyGrams - 100) < 0.01)
        #expect(abs(l.dailyGrams - 100.0 / 7) < 0.01)
    }

    // MARK: - trendDisplayFraction (agrees with rounded hero totals)

    @Test func trendDisplayFraction_usesRoundedDisplayedValues() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        let now = Date.now
        vm.now = now
        let profile = UserProfile(guidelineChoice: .who, alcoholUnit: .units)
        c.mainContext.insert(profile)
        vm.profile = profile
        // current week 19.6 g → "2.0 units"; previous week 10.2 g → "1.0 units"
        // (today-7 is always exactly one week earlier → previous week bucket)
        _ = event(daysAgo: 0, grams: 19.6, relativeTo: now, in: c.mainContext)
        _ = event(daysAgo: 7, grams: 10.2, relativeTo: now, in: c.mainContext)
        vm.events = try c.mainContext.fetch(FetchDescriptor<ConsumptionEvent>())

        // Rounded: (2.0 - 1.0) / 1.0 = 100%
        #expect(abs(vm.trendDisplayFraction - 1.0) < 0.0001)
        // Raw grams differ: (19.6 - 10.2) / 10.2 ≈ 0.92
        #expect(abs(vm.trendFraction - (19.6 - 10.2) / 10.2) < 0.01)
    }

    // MARK: - comparisonLabel (user unit, not forced grams)

    @Test func comparisonLabel_formatsInUnits() throws {
        let c = try makeContainer()
        let vm = makeVM()
        let profile = UserProfile(guidelineChoice: .who, alcoholUnit: .units)
        c.mainContext.insert(profile)
        vm.profile = profile
        let item = GuidelineComparison(guideline: .who, name: "WHO",
                                       consumedGrams: 60, limitGrams: 700)
        // WHO unit = 10 g → 6.0 / 70.0
        #expect(vm.comparisonLabel(item).hasPrefix("6.0 / 70.0"))
    }

    @Test func comparisonLabel_formatsInGrams_whenUnitIsGrams() throws {
        let c = try makeContainer()
        let vm = makeVM()
        let profile = UserProfile(guidelineChoice: .who, alcoholUnit: .grams)
        c.mainContext.insert(profile)
        vm.profile = profile
        let item = GuidelineComparison(guideline: .who, name: "WHO",
                                       consumedGrams: 60, limitGrams: 700)
        #expect(vm.comparisonLabel(item).hasPrefix("60.0 / 700.0"))
    }
}
