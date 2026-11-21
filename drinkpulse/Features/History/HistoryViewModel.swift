import SwiftUI

struct DayCell: Identifiable {
    let position: Int
    let date: Date?
    let grams: Double
    let isFuture: Bool
    let isToday: Bool
    var id: Int { position }
}

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

    func gramsByDay(
        _ events: [ConsumptionEvent],
        density: Double = AlcoholUnit.physicalDensityGramsPerMl,
        calendar: Calendar = .current
    ) -> [Date: Double] {
        events.reduce(into: [Date: Double]()) { acc, e in
            acc[calendar.startOfDay(for: e.consumptionDate), default: 0] += e.alcoholGrams(density: density)
        }
    }

    func monthCells(
        year: Int,
        month: Int,
        events: [ConsumptionEvent],
        density: Double = AlcoholUnit.physicalDensityGramsPerMl,
        calendar: Calendar = .current,
        today: Date = .now
    ) -> [DayCell] {
        guard
            let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
            let range = calendar.range(of: .day, in: .month, for: firstDay)
        else { return [] }

        let gramsMap = gramsByDay(events, density: density, calendar: calendar)
        let todayStart = calendar.startOfDay(for: today)

        let firstWeekday = calendar.firstWeekday
        let firstDayWeekday = calendar.component(.weekday, from: firstDay)
        let leadingCount = (firstDayWeekday - firstWeekday + 7) % 7
        let daysCount = range.count
        let totalCells = Int(ceil(Double(leadingCount + daysCount) / 7.0)) * 7

        var cells: [DayCell] = []
        cells.reserveCapacity(totalCells)

        for i in 0..<leadingCount {
            cells.append(DayCell(position: i, date: nil, grams: 0, isFuture: false, isToday: false))
        }

        for dayNum in range {
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: dayNum)) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let position = leadingCount + dayNum - 1
            cells.append(DayCell(
                position: position,
                date: dayStart,
                grams: gramsMap[dayStart] ?? 0,
                isFuture: dayStart > todayStart,
                isToday: calendar.isDate(dayStart, inSameDayAs: todayStart)
            ))
        }

        let trailingStart = leadingCount + daysCount
        for i in 0..<(totalCells - trailingStart) {
            cells.append(DayCell(position: trailingStart + i, date: nil, grams: 0, isFuture: false, isToday: false))
        }

        return cells
    }

    func riskColor(forGrams grams: Double, dailyLimit: Double) -> Color? {
        guard grams > 0, dailyLimit > 0 else { return nil }
        return RiskLevel.from(pct: grams / dailyLimit).tone
    }
}
