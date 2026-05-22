import Testing
import Foundation
@testable import drinkpulse

@MainActor
struct InsightsPeriodTests {

    private let cal = Calendar.current

    private func date(_ str: String) -> Date {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: str)!
    }

    // MARK: - localizedLabel

    @Test func localizedLabel_allCasesNonEmpty() {
        #expect(!InsightsPeriod.week.localizedLabel.isEmpty)
        #expect(!InsightsPeriod.month.localizedLabel.isEmpty)
        #expect(!InsightsPeriod.year.localizedLabel.isEmpty)
    }

    @Test func localizedLabel_allDistinct() {
        let labels = InsightsPeriod.allCases.map { $0.localizedLabel }
        #expect(Set(labels).count == 3)
    }

    // MARK: - minOffset

    @Test func minOffset_weekIs156() {
        #expect(InsightsPeriod.week.minOffset == -156)
    }

    @Test func minOffset_monthIs35() {
        #expect(InsightsPeriod.month.minOffset == -35)
    }

    @Test func minOffset_yearIs3() {
        #expect(InsightsPeriod.year.minOffset == -3)
    }

    // MARK: - dateRange week

    @Test func dateRange_weekContainsNow() {
        let now = date("2026-05-20")
        let range = InsightsPeriod.week.dateRange(offset: 0, now: now, calendar: cal)
        #expect(range.contains(now))
    }

    @Test func dateRange_weekSpansSevenDays() {
        let now = date("2026-05-20")
        let range = InsightsPeriod.week.dateRange(offset: 0, now: now, calendar: cal)
        #expect(cal.days(in: range).count == 7)
    }

    @Test func dateRange_weekOffsetMinus1_doesNotContainNow() {
        let now = date("2026-05-20")
        let range = InsightsPeriod.week.dateRange(offset: -1, now: now, calendar: cal)
        let today = cal.startOfDay(for: now)
        #expect(!range.contains(today))
    }

    // MARK: - dateRange month

    @Test func dateRange_monthStartsAtFirstOfMonth() {
        let now = date("2026-05-15")
        let range = InsightsPeriod.month.dateRange(offset: 0, now: now, calendar: cal)
        let comps = cal.dateComponents([.day], from: range.lowerBound)
        #expect(comps.day == 1)
    }

    @Test func dateRange_monthMayHas31Days() {
        let now = date("2026-05-15")
        let range = InsightsPeriod.month.dateRange(offset: 0, now: now, calendar: cal)
        #expect(cal.days(in: range).count == 31)
    }

    @Test func dateRange_monthOffsetMinus1_isApril() {
        let now = date("2026-05-15")
        let range = InsightsPeriod.month.dateRange(offset: -1, now: now, calendar: cal)
        let comps = cal.dateComponents([.month, .year], from: range.lowerBound)
        #expect(comps.month == 4)
        #expect(comps.year == 2026)
    }

    // MARK: - dateRange year

    @Test func dateRange_yearStartsAtJan1() {
        let now = date("2026-05-15")
        let range = InsightsPeriod.year.dateRange(offset: 0, now: now, calendar: cal)
        let comps = cal.dateComponents([.month, .day], from: range.lowerBound)
        #expect(comps.month == 1)
        #expect(comps.day == 1)
    }

    @Test func dateRange_yearContains365Days() {
        let now = date("2026-05-15")
        let range = InsightsPeriod.year.dateRange(offset: 0, now: now, calendar: cal)
        #expect(cal.days(in: range).count == 365)
    }

    @Test func dateRange_yearOffsetMinus1_is2025() {
        let now = date("2026-05-15")
        let range = InsightsPeriod.year.dateRange(offset: -1, now: now, calendar: cal)
        let comps = cal.dateComponents([.year], from: range.lowerBound)
        #expect(comps.year == 2025)
    }

    // MARK: - friendlyLabel

    @Test func friendlyLabel_week_offset0_and_minus1_differ() {
        let now = date("2026-05-20")
        let label0  = InsightsPeriod.week.friendlyLabel(offset: 0,  now: now, calendar: cal)
        let labelM1 = InsightsPeriod.week.friendlyLabel(offset: -1, now: now, calendar: cal)
        #expect(label0 != labelM1)
    }

    @Test func friendlyLabel_week_offsetMinus3_contains3() {
        let now = date("2026-05-20")
        let label = InsightsPeriod.week.friendlyLabel(offset: -3, now: now, calendar: cal)
        #expect(label.contains("3"))
    }

    @Test func friendlyLabel_month_offset0_and_minus1_differ() {
        let now = date("2026-05-20")
        let label0  = InsightsPeriod.month.friendlyLabel(offset: 0,  now: now, calendar: cal)
        let labelM1 = InsightsPeriod.month.friendlyLabel(offset: -1, now: now, calendar: cal)
        #expect(label0 != labelM1)
    }

    @Test func friendlyLabel_month_offsetMinus2_nonEmpty() {
        let now = date("2026-05-20")
        let label = InsightsPeriod.month.friendlyLabel(offset: -2, now: now, calendar: cal)
        #expect(!label.isEmpty)
    }

    @Test func friendlyLabel_year_offset0_and_minus1_differ() {
        let now = date("2026-05-20")
        let label0  = InsightsPeriod.year.friendlyLabel(offset: 0,  now: now, calendar: cal)
        let labelM1 = InsightsPeriod.year.friendlyLabel(offset: -1, now: now, calendar: cal)
        #expect(label0 != labelM1)
    }

    @Test func friendlyLabel_year_offsetMinus2_contains2() {
        let now = date("2026-05-20")
        let label = InsightsPeriod.year.friendlyLabel(offset: -2, now: now, calendar: cal)
        #expect(label.contains("2"))
    }

    // MARK: - rangeLabel

    @Test func rangeLabel_weekContainsDash() {
        let now = date("2026-05-20")
        let label = InsightsPeriod.week.rangeLabel(offset: 0, now: now, calendar: cal)
        #expect(label.contains("–"))
    }

    @Test func rangeLabel_monthNonEmpty() {
        let now = date("2026-05-20")
        let label = InsightsPeriod.month.rangeLabel(offset: 0, now: now, calendar: cal)
        #expect(!label.isEmpty)
    }

    @Test func rangeLabel_yearContains2026() {
        let now = date("2026-05-20")
        let label = InsightsPeriod.year.rangeLabel(offset: 0, now: now, calendar: cal)
        #expect(label.contains("2026"))
    }
}
