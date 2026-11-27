import Foundation

extension ChartPoint {
    /// Slots the area chart always draws for `period`, so the series keeps the same number of
    /// marks between neighbouring periods. Swift Charts morphs a series only when its mark count
    /// is unchanged (device check, 2026-11-26: July ↔ August morphed, 30 ↔ 31-day months
    /// jumped). `nil`: no padding (All Time has no prev / next navigation).
    static func morphSlotCount(for period: InsightsPeriod) -> Int? {
        switch period {
        case .week: 7
        case .month: 31
        case .year: 12
        case .allTime: nil
        }
    }

    /// `points` padded up to `count` with points that continue past the last one, one `unit`
    /// apart, at the last value (a flat line). They lie outside `visibleDomain`, so the chart
    /// clips them. Distinct dates matter: copies at the last date made `.monotone` draw a stray
    /// diagonal line. Unchanged when `points` is empty or already has `count` or more points.
    static func paddedForMorph(
        _ points: [ChartPoint], to count: Int?, unit: Calendar.Component, calendar: Calendar
    ) -> [ChartPoint] {
        guard let count, let last = points.last, points.count < count else { return points }
        let padding = (points.count..<count).compactMap { slot -> ChartPoint? in
            let steps = slot - last.slot
            guard let date = calendar.date(byAdding: unit, value: steps, to: last.date) else { return nil }
            return ChartPoint(slot: slot, date: date, grams: last.grams)
        }
        return points + padding
    }

    /// X domain of the real points: from the middle of the first point's `unit` bin to the
    /// middle of the last one's, where Swift Charts places a point plotted with `unit`. The curve
    /// then ends exactly at the last real point and the morph padding (which starts one `unit`
    /// later) stays entirely off the plot. `nil` (automatic domain) for fewer than two points.
    static func visibleDomain(
        of points: [ChartPoint], unit: Calendar.Component, calendar: Calendar
    ) -> ClosedRange<Date>? {
        guard let first = points.first, let last = points.last,
              let start = binMiddle(of: first.date, unit: unit, calendar: calendar),
              let end = binMiddle(of: last.date, unit: unit, calendar: calendar),
              start < end  // A single point would give a zero-width, non-finite X scale.
        else { return nil }
        return start...end
    }

    /// Middle of the `unit` bin that starts at `date`.
    static func binMiddle(of date: Date, unit: Calendar.Component, calendar: Calendar) -> Date? {
        guard let next = calendar.date(byAdding: unit, value: 1, to: date) else { return nil }
        return date.addingTimeInterval(next.timeIntervalSince(date) / 2)
    }
}
