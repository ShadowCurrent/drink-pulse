import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct InsightsViewModelTests {

    func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // Returns a VM with the seeded generator disabled so tests control all data.
    func makeVM() -> InsightsViewModel {
        let vm = InsightsViewModel()
        vm.dataProvider = { _ in nil }
        return vm
    }

    func event(
        daysAgo: Int = 0,
        hoursOffset: Int = 12,
        grams target: Double = 20.0,
        price: Double? = nil,
        in context: ModelContext
    ) -> ConsumptionEvent {
        let cal = Calendar.current
        let base = cal.startOfDay(for: Date.now).addingTimeInterval(Double(hoursOffset) * 3600)
        let ts = cal.date(byAdding: .day, value: -daysAgo, to: base) ?? base
        let abv = target / (500 * 0.8)
        let e = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: abv,
                                 name: "Test", category: .beer, icon: "🍺", price: price)
        context.insert(e)
        return e
    }

    // MARK: - weekdayAverages

    @Test func weekdayAverages_alwaysSevenEntries() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.weekdayAverages.count == 7)
    }

    @Test func weekdayAverages_zeroBarsWhenNoEvents() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        vm.period = .week
        #expect(vm.weekdayAverages.allSatisfy { $0.averageGrams == 0 })
    }

    @Test func weekdayAverages_dividesByWeekCountNotDayCount_monthPeriod() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.period = .month

        // Fix now to a known Monday (2026-05-18)
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let monday = fmt.date(from: "2026-05-18")!
        vm.now = monday

        let cal = Calendar.current
        // Add 40 g on a Monday 3 weeks ago (within the 90-day weekday window)
        let mondayThreeWeeksAgo = cal.date(byAdding: .weekOfYear, value: -3, to: monday)!
        let e = ConsumptionEvent(
            timestamp: mondayThreeWeeksAgo.addingTimeInterval(12 * 3600),
            volumeMl: 500, abv: 40.0 / 400, name: "Test", category: .beer, icon: "🍺"
        )
        c.mainContext.insert(e)
        vm.events = [e]

        let bars = vm.weekdayAverages
        #expect(bars.count == 7)
        // 40 g divided by the count of Mondays in the 90-day window must be < 40 g
        let mondayBar = bars.first { $0.averageGrams > 0 }
        #expect(mondayBar != nil)
        #expect((mondayBar?.averageGrams ?? 0) < 40.1)
        #expect((mondayBar?.averageGrams ?? 0) > 0)
    }

    // MARK: - heatmapCells

    @Test func heatmapCells_alwaysEightyFourCells() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        #expect(vm.heatmapCells.count == 84)
    }

    @Test func heatmapCells_oldestFirst() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        let dates = vm.heatmapCells.map(\.date)
        #expect(dates == dates.sorted())
    }

    @Test func heatmapCells_newestWeekMarkedAsCurrent() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        #expect(vm.heatmapCells.filter(\.isCurrentWeek).count == 7)
    }

    @Test func heatmapCells_gramsReflectRealEvents() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.now = .now
        let e = event(daysAgo: 0, grams: 30, in: c.mainContext)
        vm.events = [e]
        let todayCell = vm.heatmapCells.first {
            Calendar.current.isDate($0.date, inSameDayAs: Date.now)
        }
        #expect(todayCell != nil)
        #expect(abs((todayCell?.grams ?? 0) - 30) < 0.01)
    }

    @Test func heatmapCells_emptyDayHasZeroGrams() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        // Generator is disabled; all cells must be zero.
        #expect(vm.heatmapCells.allSatisfy { $0.grams == 0 })
    }

    @Test func heatmapCells_futureCellsMarkedAsFuture() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        let today = Calendar.current.startOfDay(for: .now)
        let futureCells = vm.heatmapCells.filter(\.isFuture)
        // Every future cell must have a date strictly after today
        #expect(futureCells.allSatisfy { $0.date > today })
        // Today and past cells must not be marked future
        let nonFutureCells = vm.heatmapCells.filter { !$0.isFuture }
        #expect(nonFutureCells.allSatisfy { $0.date <= today })
    }

    // MARK: - bingeEpisodes (day-based: days where total ≥ 60 g)

    @Test func bingeEpisodes_zeroWhenNoEvents() {
        let vm = makeVM()
        vm.events = []
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 0)
    }

    @Test func bingeEpisodes_zeroWhenBelowThreshold() throws {
        let c = try makeContainer()
        let vm = makeVM()
        // 59 g on one day — below the 60 g threshold
        vm.events = [event(daysAgo: 0, grams: 59, in: c.mainContext)]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 0)
    }

    @Test func bingeEpisodes_oneWhenAtThreshold() throws {
        let c = try makeContainer()
        let vm = makeVM()
        vm.events = [event(daysAgo: 0, grams: 60, in: c.mainContext)]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 1)
    }

    @Test func bingeEpisodes_twoDaysAboveThreshold_countsBoth() throws {
        let c = try makeContainer()
        let vm = makeVM()
        // Two separate days each with ≥ 60 g → 2 binge days
        vm.events = [
            event(daysAgo: 0, grams: 60, in: c.mainContext),
            event(daysAgo: 1, grams: 60, in: c.mainContext),
        ]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 2)
    }

    @Test func bingeEpisodes_multipleDrinksOnSameDay_combinedForThreshold() throws {
        let c = try makeContainer()
        let vm = makeVM()
        // Two events on the same day: 35 + 35 = 70 g → 1 binge day
        vm.events = [
            event(daysAgo: 0, hoursOffset: 12, grams: 35, in: c.mainContext),
            event(daysAgo: 0, hoursOffset: 13, grams: 35, in: c.mainContext),
        ]
        vm.now = .now
        #expect(vm.bingeEpisodesThisMonth == 1)
    }

    @Test func bingeEpisodes_eventOutsideActivePeriodNotCounted() throws {
        let c = try makeContainer()
        let vm = makeVM()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        vm.now = fmt.date(from: "2026-05-15")!
        // Event from April 20 — outside the current week (May 11–17)
        let lastMonth = fmt.date(from: "2026-04-20")!
        let e = ConsumptionEvent(timestamp: lastMonth, volumeMl: 500, abv: 100.0 / 400,
                                 name: "Test", category: .beer, icon: "🍺")
        c.mainContext.insert(e)
        vm.events = [e]
        #expect(vm.bingeEpisodesThisMonth == 0)
    }

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
        // 100 g pure alcohol × 7 kcal/g = 700 kcal
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
        vm.now = .now
        vm.events = [
            event(daysAgo: 0, grams: 20, price: 5.0, in: c.mainContext),
            event(daysAgo: 1, grams: 20, price: 3.5, in: c.mainContext),
        ]
        #expect(abs((vm.monthSpend ?? 0) - 8.5) < 0.01)
    }

    // MARK: - InsightsPeriod navigation

    @Test func period_navigatePrev_decreasesOffset() {
        let vm = makeVM()
        vm.period = .week
        vm.navigatePrev()
        #expect(vm.weekOffset == -1)
    }

    @Test func period_navigateNext_doesNothingAtCurrentPeriod() {
        let vm = makeVM()
        vm.period = .week
        vm.navigateNext()
        #expect(vm.weekOffset == 0)
    }

    @Test func period_jumpToNow_resetsOffset() {
        let vm = makeVM()
        vm.period = .week
        vm.navigatePrev()
        vm.navigatePrev()
        vm.jumpToNow()
        #expect(vm.weekOffset == 0)
        #expect(vm.isCurrentPeriod)
    }

    @Test func period_independentOffsets_preservedAcrossScopeSwitch() {
        let vm = makeVM()
        vm.period = .week
        vm.navigatePrev()
        vm.navigatePrev()
        vm.period = .month
        vm.navigatePrev()
        // Switch back — week offset should be -2, not reset
        vm.period = .week
        #expect(vm.weekOffset == -2)
        #expect(vm.monthOffset == -1)
    }

    @Test func period_cannotNavigateBeyondMinOffset() {
        let vm = makeVM()
        vm.period = .year
        for _ in 0..<10 {
            vm.navigatePrev()
        }
        #expect(vm.yearOffset == InsightsPeriod.year.minOffset)
    }

    @Test func period_navigateNext_increasesOffset_whenNegative() {
        let vm = makeVM()
        vm.period = .week
        vm.navigatePrev()      // weekOffset = -1
        vm.navigateNext()      // weekOffset = 0
        #expect(vm.weekOffset == 0)
        #expect(vm.isCurrentPeriod)
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
        // profile = nil → weeklyGoalGrams ?? 100
        let l = vm.limits(for: .custom)
        #expect(abs(l.weeklyGrams - 100) < 0.01)
        #expect(abs(l.dailyGrams - 100.0 / 7) < 0.01)
    }

    // MARK: - seriesData (year)

    @Test func seriesData_yearPeriodHasTwelveMonthlyPoints() {
        let vm = makeVM()
        vm.period = .year
        vm.now = .now
        vm.events = []
        #expect(vm.seriesData.count == 12)
    }

    // MARK: - friendlyLabel / rangeLabel (VM computed properties)

    @Test func friendlyLabel_currentAndPrevPeriodDiffer() {
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        let current = vm.friendlyLabel
        vm.navigatePrev()
        let prev = vm.friendlyLabel
        #expect(current != prev)
    }

    @Test func rangeLabel_weekContainsDash() {
        let vm = makeVM()
        vm.period = .week
        vm.now = .now
        #expect(vm.rangeLabel.contains("–"))
    }

    // MARK: - formattedValue

    @Test func formattedValue_noProfile_returnsGramsString() {
        let vm = makeVM()
        #expect(vm.formattedValue(42.0) == "42 g")
    }

    // MARK: - formattedSpend

    @Test func formattedSpend_noProfile_nonEmpty() {
        let vm = makeVM()
        #expect(!vm.formattedSpend(5.0).isEmpty)
    }
}
