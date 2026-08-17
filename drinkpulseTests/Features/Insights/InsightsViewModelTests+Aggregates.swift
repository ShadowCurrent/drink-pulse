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

    @Test func seriesData_currentYearHasMonthsUpToNow() {
        let vm = makeVM()
        vm.period = .year
        let pinned = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        vm.now = pinned
        vm.events = []
        #expect(vm.seriesData.count == 6)
    }

    @Test func seriesData_pastYearHasTwelveMonthlyPoints() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .year
        let pinned = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        vm.now = pinned
        vm.events = [event(daysAgo: 400, grams: 10, relativeTo: pinned, in: c.mainContext)]
        vm.navigatePrev()
        #expect(vm.activeOffset == -1)
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
        vm.events = [event(daysAgo: 0, grams: 100, in: c.mainContext)]
        #expect(vm.monthCaloriesKcal == 700)
    }

    @Test func periodCaloriesKcal_identicalAcrossDisplayUnits() throws {
        let c = try makeContainer()
        let gramsVM = InsightsViewModel()
        gramsVM.profile = UserProfile(guidelineChoice: .who, alcoholUnit: .grams)
        let drinksVM = InsightsViewModel()
        drinksVM.profile = UserProfile(guidelineChoice: .who, alcoholUnit: .standardDrinks)
        let e1 = ConsumptionEvent(consumptionDate: .now, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        let e2 = ConsumptionEvent(consumptionDate: .now, volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        c.mainContext.insert(e1); c.mainContext.insert(e2)
        gramsVM.now = .now;  gramsVM.events = [e1]
        drinksVM.now = .now; drinksVM.events = [e2]
        #expect(gramsVM.periodCaloriesKcal == drinksVM.periodCaloriesKcal)
        #expect(gramsVM.periodCaloriesKcal == 138)
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
        #expect(total == vm.elapsedDays.count)
        #expect(free == total)
    }

    @Test func drinkFreeDays_oneDrinkingDay() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        vm.events = [event(daysAgo: 0, grams: 30, in: c.mainContext)]
        let (free, total) = vm.drinkFreeDays
        #expect(total == vm.elapsedDays.count)
        #expect(free == total - 1)
    }

    @Test func drinkFreeDays_monthExcludesFutureDays() {
        let vm = makeVM()
        vm.events = []
        vm.now = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 18))!
        vm.period = .month
        let (free, total) = vm.drinkFreeDays
        #expect(total == 18)
        #expect(free == 18)
    }

    @Test func drinkFreeDays_monthWithDrinkingDay_countsElapsedOnly() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .month
        let pinnedNow = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 18))!
        vm.now = pinnedNow
        vm.events = [event(daysAgo: 13, grams: 30, relativeTo: pinnedNow, in: c.mainContext)]
        let (free, total) = vm.drinkFreeDays
        #expect(total == 18)
        #expect(free == 17)
    }

    // MARK: - longestSoberStreak

    @Test func longestSoberStreak_noEvents_spansAllElapsedDaysOfWeek() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.longestSoberStreak == vm.elapsedDays.count)
    }

    @Test func longestSoberStreak_reducedWhenHasDrinkingDay() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        vm.events = [event(daysAgo: 0, grams: 30, in: c.mainContext)]
        #expect(vm.longestSoberStreak < 7)
    }

    @Test func longestSoberStreak_monthExcludesFutureDays() {
        let vm = makeVM()
        vm.events = []
        vm.now = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 18))!
        vm.period = .month
        #expect(vm.longestSoberStreak == 18)
    }

    @Test func longestSoberStreak_monthStreakEndsAtToday_notEndOfMonth() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .month
        let pinnedNow = Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 18))!
        vm.now = pinnedNow
        vm.events = [event(daysAgo: 13, grams: 30, relativeTo: pinnedNow, in: c.mainContext)]
        #expect(vm.longestSoberStreak == 13)
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
        #expect(abs((perDay ?? 0) - 1.0) < 0.01)
    }

    // MARK: - limits(for: .custom)

    @Test func limits_custom_usesDefaultWeeklyGoalWhenNoProfile() {
        let vm = makeVM()
        let l = vm.limits(for: .custom)
        #expect(abs(l.weeklyGrams - 100) < 0.01)
        #expect(abs(l.dailyGrams - 100.0 / 7) < 0.01)
    }

    // MARK: - trendFraction (exact; the unit constant cancels in the ratio)

    @Test func trendFraction_isExactRatio() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .week
        let now = Date.now
        vm.now = now
        _ = event(daysAgo: 0, grams: 20, relativeTo: now, in: c.mainContext)
        _ = event(daysAgo: 7, grams: 10, relativeTo: now, in: c.mainContext)
        vm.events = try c.mainContext.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(abs(vm.trendFraction - 1.0) < 0.0001)
    }

    // MARK: - comparisonLabel (user unit, not forced grams)

    @Test func comparisonLabel_formatsInStandardDrinks() throws {
        let c = try makeContainer()
        let vm = makeVM()
        let profile = UserProfile(guidelineChoice: .who, alcoholUnit: .standardDrinks)
        c.mainContext.insert(profile)
        vm.profile = profile
        let item = GuidelineComparison(guideline: .who, name: "WHO",
                                       consumedGrams: 60, limitGrams: 700)
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
