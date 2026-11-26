import Foundation
import Testing
@testable import drinkpulse

/// Spec: docs/superpowers/specs/2026-11-26-alcohol-free-day-rule-design.md.
/// The `example*` tests assert the "New" column of the spec's hand-verification table.
struct AlcoholFreeDayRuleTests {

    // MARK: - Fixture

    private static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        c.firstWeekday = 2
        return c
    }()

    private static let beer = 500 * 0.05 * AlcoholUnit.physicalDensityGramsPerMl // 19.725 g

    private func d(_ m: Int, _ day: Int, _ h: Int = 12) -> Date {
        Self.cal.date(from: DateComponents(year: 2026, month: m, day: day, hour: h)) ?? .distantPast
    }

    private func days(_ from: Date, _ to: Date) -> [Date] {
        var result: [Date] = []
        var current = Self.cal.startOfDay(for: from)
        let end = Self.cal.startOfDay(for: to)
        while current <= end {
            result.append(current)
            current = Self.cal.date(byAdding: .day, value: 1, to: current) ?? .distantFuture
        }
        return result
    }

    private var now: Date { d(11, 26, 10) }
    private var week: [Date] { days(d(11, 23), d(11, 29)) }
    private var month: [Date] { days(d(11, 1), d(11, 30)) }

    private func rule(first: Date?, now: Date? = nil) -> AlcoholFreeDayRule {
        AlcoholFreeDayRule(firstEventDate: first, now: now ?? self.now, calendar: Self.cal)
    }

    private func lookup(_ entries: [(Date, Double)]) -> (Date) -> Double {
        var map: [Date: Double] = [:]
        for (date, grams) in entries { map[Self.cal.startOfDay(for: date), default: 0] += grams }
        return { map[$0] ?? 0 }
    }

    // MARK: - Spec examples

    @Test func example1_firstLogBeerWednesday() {
        let r = rule(first: d(11, 25, 18))
        let g = lookup([(d(11, 25, 18), Self.beer)])
        let free = r.alcoholFreeDays(in: week, grams: g)
        #expect(free.count == 0 && free.total == 1)
        #expect(r.longestAlcoholFreeStreak(in: week, grams: g) == 0)
        #expect(r.alcoholFreeDates(in: month, grams: g).count == 0)
        #expect(r.currentAlcoholFreeStreak(grams: g) == 0)
    }

    @Test func example2_firstLogZeroPercentWednesday() {
        let r = rule(first: d(11, 25, 18))
        let g = lookup([])
        let free = r.alcoholFreeDays(in: week, grams: g)
        #expect(free.count == 1 && free.total == 1)
        #expect(r.currentAlcoholFreeStreak(grams: g) == 1)
        #expect(r.alcoholFreeDates(in: month, grams: g).count == 1)
    }

    @Test func example3_loggingSinceOctober_alcoholOnlySaturday21() {
        let r = rule(first: d(10, 1))
        let g = lookup([(d(11, 21, 20), Self.beer)])
        let free = r.alcoholFreeDays(in: week, grams: g)
        #expect(free.count == 3 && free.total == 3)
        #expect(r.longestAlcoholFreeStreak(in: week, grams: g) == 3)
        #expect(r.currentAlcoholFreeStreak(grams: g) == 4)
        #expect(r.alcoholFreeDates(in: month, grams: g).count == 24)
    }

    @Test func example4_asThreePlus70gToday() {
        let r = rule(first: d(10, 1))
        let g = lookup([(d(11, 21, 20), Self.beer), (d(11, 26, 20), 70)])
        let free = r.alcoholFreeDays(in: week, grams: g)
        #expect(free.count == 3 && free.total == 4)
        #expect(AlcoholFreeDayRule.heavyDayCount(in: week, grams: g) == 1)
        #expect(r.currentAlcoholFreeStreak(grams: g) == 0)
        #expect(r.alcoholFreeDates(in: month, grams: g).count == 24)
    }

    @Test func example5_mondayMorningNothingLogged() {
        let r = rule(first: d(10, 1), now: d(11, 23, 8))
        let g = lookup([(d(11, 21, 20), Self.beer)])
        let free = r.alcoholFreeDays(in: week, grams: g)
        #expect(free.count == 0 && free.total == 0)
        #expect(r.longestAlcoholFreeStreak(in: week, grams: g) == 0)
    }

    @Test func example6_previousWeek_firstLogThursday19() {
        let r = rule(first: d(11, 19, 19))
        let g = lookup([(d(11, 19, 19), Self.beer)])
        let previousWeek = days(d(11, 16), d(11, 22))
        let free = r.alcoholFreeDays(in: previousWeek, grams: g)
        #expect(free.count == 3 && free.total == 4)
        #expect(r.longestAlcoholFreeStreak(in: previousWeek, grams: g) == 3)
    }

    @Test func example7_heavyThreshold_dependsOnModeDensity() {
        let gramsMode = 1500 * 1 * 0.05 * AlcoholUnit.grams.density(for: .who)
        let ukUnitsMode = 1500 * 1 * 0.05 * AlcoholUnit.standardDrinks.density(for: .uk)
        #expect(AlcoholFreeDayRule.isHeavy(grams: gramsMode) == false)
        #expect(AlcoholFreeDayRule.isHeavy(grams: ukUnitsMode) == true)
    }

    // MARK: - Edge cases

    @Test func noEvents_nothingCounts() {
        let r = rule(first: nil)
        let g = lookup([(d(11, 24), Self.beer)])
        let free = r.alcoholFreeDays(in: week, grams: g)
        #expect(free.count == 0 && free.total == 0)
        #expect(r.currentAlcoholFreeStreak(grams: g) == 0)
        #expect(r.alcoholFreeDates(in: month, grams: g).isEmpty)
    }

    @Test func futureDay_isNotCounted() {
        #expect(rule(first: d(10, 1)).status(of: d(11, 27), grams: 0) == .notCounted)
        #expect(rule(first: d(10, 1)).status(of: d(11, 27), grams: 30) == .notCounted)
    }

    @Test func dayBeforeStart_isNotCounted() {
        #expect(rule(first: d(11, 20, 15)).status(of: d(11, 19, 23), grams: 0) == .notCounted)
        #expect(rule(first: d(11, 20, 15)).status(of: d(11, 20, 1), grams: 0) == .alcoholFree)
    }

    @Test func status_normalisesTimeOfDay() {
        let r = rule(first: d(10, 1))
        let lateEvening = Self.cal.date(from: DateComponents(year: 2026, month: 11, day: 24,
                                                              hour: 23, minute: 59)) ?? .distantPast
        #expect(r.status(of: lateEvening, grams: 0) == r.status(of: d(11, 24, 0), grams: 0))
        #expect(r.status(of: lateEvening, grams: 0) == .alcoholFree)
        #expect(r.status(of: d(11, 26, 23), grams: 5) == .drinking)
    }

    @Test func futureFirstEvent_nothingCounts() {
        let r = rule(first: d(11, 28))
        let g = lookup([])
        let free = r.alcoholFreeDays(in: week, grams: g)
        #expect(free.count == 0 && free.total == 0)
        #expect(r.currentAlcoholFreeStreak(grams: g) == 0)
    }

    @Test func today_withoutAlcohol_isNotCounted_withAlcohol_isDrinking() {
        let r = rule(first: d(10, 1))
        #expect(r.status(of: d(11, 26, 9), grams: 0) == .notCounted)
        #expect(r.status(of: d(11, 26, 9), grams: 0.1) == .drinking)
    }

    @Test func longestStreak_resetsOnNotCountedAndDrinkingDays() {
        let r = rule(first: d(11, 2))
        let g = lookup([(d(11, 10), Self.beer)])
        // Nov 1 not counted, Nov 2-9 free (8), Nov 10 drinking, Nov 11-25 free (15), 26+ not counted.
        #expect(r.longestAlcoholFreeStreak(in: month, grams: g) == 15)
    }

    /// Final review (plan 0050): Chile skips midnight when DST starts (2026-09-06 begins at
    /// 01:00), so walking back by `date(byAdding: .day, value: -1)` lands on 01:00. The streak
    /// must still look grams up by start of day and stop at the drinking day (Sep 3).
    @Test func currentStreak_acrossMidnightDSTJump_stopsAtDrinkingDay() {
        var santiago = Calendar(identifier: .gregorian)
        santiago.timeZone = TimeZone(identifier: "America/Santiago") ?? .gmt
        func day(_ m: Int, _ d: Int, _ h: Int = 12) -> Date {
            santiago.date(from: DateComponents(year: 2026, month: m, day: d, hour: h)) ?? .distantPast
        }
        let drinking = santiago.startOfDay(for: day(9, 3))
        let r = AlcoholFreeDayRule(firstEventDate: day(8, 30), now: day(9, 10), calendar: santiago)
        // Sep 4 … Sep 9 are alcohol-free.
        #expect(r.currentAlcoholFreeStreak { $0 == drinking ? Self.beer : 0 } == 6)
    }

    @Test func isHeavy_atExactly60_isTrue() {
        #expect(AlcoholFreeDayRule.isHeavy(grams: 60))
        #expect(AlcoholFreeDayRule.heavyDayThresholdGrams == 60)
    }

    @Test func isHeavy_below60_isFalse() {
        #expect(AlcoholFreeDayRule.isHeavy(grams: 59.999) == false)
    }
}
