import Testing
import Foundation
@testable import drinkpulse

/// Day titles per plan 0045 D0045-2: wide weekday, day, abbreviated month; the year only
/// for a day outside the current year.
@MainActor
extension HistoryViewModelTests {

    private func titleFixture() throws -> (cal: Calendar, today: Date, yesterday: Date) {
        let cal = Calendar.current
        let now = try #require(cal.date(from: DateComponents(year: 2026, month: 11, day: 20, hour: 9)))
        let today = cal.startOfDay(for: now)
        let yesterday = try #require(cal.date(byAdding: .day, value: -1, to: today))
        return (cal, today, yesterday)
    }

    @Test func test_sectionTitle_today_isToday() throws {
        let f = try titleFixture()
        let title = vm.sectionTitle(for: f.today, todayStart: f.today, yesterdayStart: f.yesterday, calendar: f.cal)
        #expect(title == String(localized: "history.today"))
    }

    @Test func test_sectionTitle_yesterday_isYesterday() throws {
        let f = try titleFixture()
        let title = vm.sectionTitle(for: f.yesterday, todayStart: f.today, yesterdayStart: f.yesterday, calendar: f.cal)
        #expect(title == String(localized: "history.yesterday"))
    }

    @Test func test_sectionTitle_otherDayThisYear_hasWideWeekdayAndNoYear() throws {
        let f = try titleFixture()
        let day = try #require(f.cal.date(from: DateComponents(year: 2026, month: 1, day: 10)))
        let title = vm.sectionTitle(for: day, todayStart: f.today, yesterdayStart: f.yesterday, calendar: f.cal)
        #expect(title == day.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
    }

    @Test func test_sectionTitle_dayInEarlierYear_includesYear() throws {
        let f = try titleFixture()
        let day = try #require(f.cal.date(from: DateComponents(year: 2025, month: 11, day: 10)))
        let title = vm.sectionTitle(for: day, todayStart: f.today, yesterdayStart: f.yesterday, calendar: f.cal)
        #expect(title == day.formatted(.dateTime.weekday(.wide).day().month(.abbreviated).year()))
    }
}
