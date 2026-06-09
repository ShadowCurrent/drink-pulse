import Foundation

extension InsightsViewModel {

    // MARK: - Area chart series

    var seriesData: [ChartPoint] {
        switch period {
        case .week, .month:
            return activeDays.map { ChartPoint(date: $0, grams: gramsForDay($0)) }
        case .year, .allTime:
            return monthlyBuckets(in: effectiveDateRange)
        }
    }

    private func monthlyBuckets(in range: ClosedRange<Date>) -> [ChartPoint] {
        var buckets: [Date: Double] = [:]
        var current = cal.startOfDay(for: range.lowerBound)
        while current <= range.upperBound {
            if let ms = cal.dateInterval(of: .month, for: current)?.start {
                buckets[ms, default: 0] += gramsForDay(current)
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return buckets.map { ChartPoint(date: $0.key, grams: $0.value) }.sorted { $0.date < $1.date }
    }

    // MARK: - Weekday averages (over the selected period window)

    var weekdayAverages: [WeekdayBar] {
        // Always based on the selected period's window — not a fixed 90-day window.
        // The end is clamped to `now`: for current periods the range's upper bound is
        // in the future (e.g. Dec 31 of the current year), and counting those future
        // days would both empty the chart and dilute the per-weekday averages.
        let windowStart = cal.startOfDay(for: activeDateRange.lowerBound)
        let windowEnd = min(activeDateRange.upperBound, now)
        let days = windowStart <= windowEnd ? cal.days(in: windowStart...windowEnd) : []
        let firstDay = cal.firstWeekday
        var counts = [Int: Int]()
        var sums   = [Int: Double]()

        for day in days {
            let col = columnIndex(for: day, firstDay: firstDay)
            counts[col, default: 0] += 1
            sums[col, default: 0]   += gramsForDay(day)
        }

        return (0..<7).map { col in
            let weekday = ((firstDay - 1 + col) % 7) + 1
            let avg = counts[col].map { Double(sums[col, default: 0]) / Double($0) } ?? 0
            return WeekdayBar(
                weekdayIndex: col,
                label: shortWeekdayLabel(weekday: weekday),
                averageGrams: avg,
                riskLevel: riskLevel(for: avg)
            )
        }
    }

    // MARK: - Private helpers

    func columnIndex(for date: Date, firstDay: Int) -> Int {
        let weekday = cal.component(.weekday, from: date)
        return (weekday - firstDay + 7) % 7
    }

    private func shortWeekdayLabel(weekday: Int) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale.current
        guard weekday >= 1, weekday <= 7 else { return "" }
        return fmt.shortStandaloneWeekdaySymbols[weekday - 1]
    }
}
