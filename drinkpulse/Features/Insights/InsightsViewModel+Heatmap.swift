import Foundation

extension InsightsViewModel {

    // MARK: - Activity heatmap (4 × 7 = 28 cells, oldest first)

    var heatmapCells: [HeatmapCell] {
        let firstDay = cal.firstWeekday
        // Find the start of the current calendar week
        guard let currentWeekStart = cal.dateInterval(of: .weekOfYear, for: cal.startOfDay(for: now))?.start else {
            return []
        }
        var cells: [HeatmapCell] = []
        for weekOffset in (0..<4).reversed() {  // 3 = most recent, 0 = oldest
            let weekRow = 3 - weekOffset
            guard let weekStart = cal.date(byAdding: .day, value: -weekOffset * 7, to: currentWeekStart) else { continue }
            let isCurrentWeek = weekOffset == 0
            for dayOffset in 0..<7 {
                guard let day = cal.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
                let dayStart = cal.startOfDay(for: day)
                guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { continue }
                let g = events.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
                              .reduce(0) { $0 + $1.pureAlcoholGrams }
                // dayOffset corresponds to column relative to weekStart,
                // but weekStart is already aligned to firstWeekday via cal.dateInterval(of: .weekOfYear).
                // So column index = dayOffset directly.
                cells.append(HeatmapCell(
                    date: dayStart,
                    grams: g,
                    weekIndex: weekRow,
                    dayIndex: dayOffset,
                    isCurrentWeek: isCurrentWeek
                ))
            }
        }
        return cells.sorted { $0.date < $1.date }
    }

    // MARK: - Binge episodes this month

    var bingeEpisodesThisMonth: Int {
        let threshold = bingeThreshold(for: guidelineChoice)
        guard let monthStart = cal.date(from: cal.dateComponents(Set<Calendar.Component>([.year, .month]), from: now)) else { return 0 }
        let monthEvents = events
            .filter { $0.timestamp >= monthStart }
            .sorted { $0.timestamp < $1.timestamp }

        var episodeCount = 0
        var sessionStart: Date?
        var sessionEnd: Date?
        var sessionGrams: Double = 0
        let sessionGap: TimeInterval = 3 * 3600

        for event in monthEvents {
            if let end = sessionEnd, event.timestamp.timeIntervalSince(end) > sessionGap {
                // New session — evaluate previous
                if sessionGrams >= threshold { episodeCount += 1 }
                sessionGrams = 0
                sessionStart = event.timestamp
            }
            if sessionStart == nil { sessionStart = event.timestamp }
            sessionGrams += event.pureAlcoholGrams
            sessionEnd = event.timestamp
        }
        // Evaluate last session
        if sessionStart != nil, sessionGrams >= threshold { episodeCount += 1 }
        return episodeCount
    }

    private func bingeThreshold(for guideline: GuidelineChoice) -> Double {
        switch guideline {
        case .uk:            return 56   // 7 UK units × 8 g
        case .us:            return 70   // 5 NIAAA drinks × 14 g
        default:             return 60   // WHO / DE / custom
        }
    }
}
