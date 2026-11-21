import SwiftUI

struct DaySection: Identifiable, Equatable {
    let id: Date
    let title: String
    let events: [ConsumptionEvent]
}

@Observable @MainActor final class HistoryViewModel {

    static let listPageDays = 7

    /// Start of day of one page before `now`, so the oldest loaded day is complete and its
    /// header total is the whole day (plan 0045, D0045-3).
    func initialWindowStart(from now: Date = .now, calendar: Calendar = .current) -> Date {
        pageBack(from: now, calendar: calendar)
    }

    func extendedWindowStart(from current: Date, calendar: Calendar = .current) -> Date {
        pageBack(from: current, calendar: calendar)
    }

    private func pageBack(from date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: calendar.date(byAdding: .day, value: -Self.listPageDays, to: date) ?? date)
    }

    func extendedWindowStart(from current: Date, earliest: Date?, calendar: Calendar = .current) -> Date {
        guard let earliest else { return extendedWindowStart(from: current, calendar: calendar) }
        var candidate = extendedWindowStart(from: current, calendar: calendar)
        var iterations = 0
        while earliest < candidate, iterations < 10_000 {
            let next = extendedWindowStart(from: candidate, calendar: calendar)
            guard next != candidate else { break }
            candidate = next
            iterations += 1
        }
        return candidate
    }

    /// Calendar paging range: start of the earliest event's month (or this month) … end of today.
    /// Day-stable, so `DecoratedCalendar` does not reset its range on every render.
    func calendarRange(earliest: Date?, now: Date = .now, calendar: Calendar = .current) -> DateInterval {
        let today = calendar.dateInterval(of: .day, for: now) ?? DateInterval(start: now, duration: 0)
        let first = earliest.map { min($0, now) } ?? now
        let start = calendar.dateInterval(of: .month, for: first)?.start ?? today.start
        return DateInterval(start: start, end: today.end)
    }

    func hasMoreToLoad(earliest: Date?, windowStart: Date) -> Bool {
        guard let earliest else { return false }
        return earliest < windowStart
    }

    func daySections(
        _ events: [ConsumptionEvent],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [DaySection] {
        let todayStart = calendar.startOfDay(for: now)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)
        let dict = Dictionary(grouping: events) {
            calendar.startOfDay(for: $0.consumptionDate)
        }
        return dict
            .sorted { $0.key > $1.key }
            .map { day, dayEvents in
                DaySection(
                    id: day,
                    title: sectionTitle(for: day, todayStart: todayStart, yesterdayStart: yesterdayStart,
                                        calendar: calendar),
                    events: dayEvents
                )
            }
    }

    /// "Today", "Yesterday", else wide weekday + day + abbreviated month; the year only when
    /// the day is outside the current year (plan 0045, D0045-2).
    func sectionTitle(for day: Date, todayStart: Date, yesterdayStart: Date?, calendar: Calendar) -> String {
        if day == todayStart { return String(localized: "history.today") }
        if let yesterdayStart, day == yesterdayStart { return String(localized: "history.yesterday") }
        let style = Date.FormatStyle.dateTime.weekday(.wide).day().month(.abbreviated)
        if calendar.isDate(day, equalTo: todayStart, toGranularity: .year) {
            return day.formatted(style)
        }
        return day.formatted(style.year())
    }
}
