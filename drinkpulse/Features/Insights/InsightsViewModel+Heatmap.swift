import Foundation

extension InsightsViewModel {

    // MARK: - Activity heatmap (12 × 7 = 84 cells)
    // Anchored to the selected period's end date, oldest week on top.

    var heatmapCells: [HeatmapCell] {
        let periodEnd = cal.startOfDay(for: activeDateRange.upperBound)
        let today = cal.startOfDay(for: now)
        guard let newestWeekStart = cal.dateInterval(of: .weekOfYear, for: periodEnd)?.start else {
            return []
        }

        let totalWeeks = 12
        var cells: [HeatmapCell] = []

        for weekOffset in (0..<totalWeeks).reversed() {
            let weekRow = (totalWeeks - 1) - weekOffset
            let isNewestWeek = (weekRow == totalWeeks - 1)
            guard let weekStart = cal.date(
                byAdding: .day, value: -weekOffset * 7, to: newestWeekStart
            ) else { continue }

            for dayOffset in 0..<7 {
                guard let day = cal.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                    continue
                }
                let dayStart = cal.startOfDay(for: day)
                let isFuture = dayStart > today
                cells.append(HeatmapCell(
                    date: dayStart,
                    grams: isFuture ? 0 : gramsForDay(day),
                    weekIndex: weekRow,
                    dayIndex: dayOffset,
                    isCurrentWeek: isNewestWeek,
                    isFuture: isFuture
                ))
            }
        }

        return cells.sorted { $0.date < $1.date }
    }
}
