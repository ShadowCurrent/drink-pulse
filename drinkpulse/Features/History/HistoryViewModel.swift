import SwiftUI

struct DayCell: Identifiable {
    let position: Int
    let date: Date?      // nil = leading/trailing padding cell
    let grams: Double
    let isFuture: Bool
    let isToday: Bool
    var id: Int { position }
}

/// One day's worth of History rows, with its heading already rendered.
///
/// The title is stored, not computed, so no date formatting happens during a body
/// pass (A4-2), and `id` is the day's start-of-day — the same value the list used to
/// pin with an explicit identity modifier, which is now redundant (A6-2).
struct DaySection: Identifiable, Equatable {
    let id: Date
    let title: String
    let events: [ConsumptionEvent]
}

@Observable @MainActor final class HistoryViewModel {

    /// List window grows backward one fixed-size page at a time.
    static let listPageDays = 7

    /// Start date for the initial list window: `listPageDays` before `now`.
    func initialWindowStart(from now: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: -Self.listPageDays, to: now) ?? now
    }

    /// Next window start when loading more: one page earlier than `current`.
    func extendedWindowStart(from current: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: -Self.listPageDays, to: current) ?? current
    }

    /// Extends `current` by one or more `listPageDays` pages, collapsing any
    /// consecutive pages that contain no events (e.g. a multi-week stretch
    /// with nothing logged) into a single jump — so one pagination trigger
    /// (one scroll-to-bottom) never needs to fire repeatedly to cross a gap.
    /// `earliest` is the oldest logged event's date (`nil` when there are no
    /// events at all, in which case this behaves like the single-page
    /// overload). See debug session history-scrollview-bugs (BUG 2 follow-up:
    /// a reliable per-page trigger repeatedly re-firing across an empty
    /// stretch caused runaway re-renders under load).
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

    /// True when older entries exist before the loaded window — i.e. the earliest
    /// event predates `windowStart`. Drives the load-more sentinel vs. end-of-list footer.
    func hasMoreToLoad(earliest: Date?, windowStart: Date) -> Bool {
        guard let earliest else { return false }
        return earliest < windowStart
    }

    /// Groups events into day sections, newest day first, each carrying its finished
    /// heading. Replaces the old grouping helper: grouping, day ordering and titling
    /// are now one pure function that runs once per data change instead of a
    /// dictionary build, two sorts and up to seven date formats per body evaluation
    /// (B8-1, A4-2).
    ///
    /// `now` is injected rather than read from the ambient clock so titles are
    /// deterministic in tests and so a day-rollover refresh is possible later.
    ///
    /// - Precondition: `events` must already be ordered the way they should appear
    ///   *within* a day. Both production callers pass `@Query` results sorted
    ///   descending by `consumptionDate`, so the former per-group re-sort was
    ///   redundant and has been dropped (B8-2). `Dictionary(grouping:)` preserves the
    ///   relative order of elements inside each group, which the
    ///   `daySections_preservesInputOrderWithinADay` test pins — if that test ever
    ///   fails, restore the per-group sort rather than weakening the test.
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
                    title: sectionTitle(for: day, todayStart: todayStart, yesterdayStart: yesterdayStart),
                    events: dayEvents
                )
            }
    }

    /// Heading for one day, computed once per section from the injected clock.
    private func sectionTitle(for day: Date, todayStart: Date, yesterdayStart: Date?) -> String {
        if day == todayStart { return String(localized: "history.today") }
        if let yesterdayStart, day == yesterdayStart { return String(localized: "history.yesterday") }
        return day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
    }

    // `density` is the active display unit's density, so calendar shading and totals
    // match the rest of the app (mode-mass vs physical-gram limits). See plan-0025.
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
        return RiskLevel.from(pct: grams / dailyLimit).color
    }
}
