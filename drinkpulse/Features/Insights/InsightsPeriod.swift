import Foundation

enum InsightsPeriod: String, CaseIterable, Hashable {
    case week, month, year

    func dateRange(now: Date, calendar: Calendar) -> ClosedRange<Date> {
        let today = calendar.startOfDay(for: now)
        switch self {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            return start...now
        case .month:
            let start = calendar.date(byAdding: .day, value: -29, to: today) ?? today
            return start...now
        case .year:
            let start = calendar.date(byAdding: .day, value: -364, to: today) ?? today
            return start...now
        }
    }

    var bucketComponent: Calendar.Component {
        switch self {
        case .week:  return .day
        case .month: return .weekOfYear
        case .year:  return .month
        }
    }

    var localizedLabel: String {
        switch self {
        case .week:  return String(localized: "insights.period.week")
        case .month: return String(localized: "insights.period.month")
        case .year:  return String(localized: "insights.period.year")
        }
    }
}

// MARK: - Chart point (area chart)

struct ChartPoint: Identifiable {
    let date: Date        // bucket start
    let grams: Double
    var id: Date { date }
}

// MARK: - Weekday bar

struct WeekdayBar: Identifiable {
    let weekdayIndex: Int  // 0-based column from locale's first weekday
    let label: String
    let averageGrams: Double
    let riskLevel: RiskLevel
    var id: Int { weekdayIndex }
}

// MARK: - Heatmap cell

struct HeatmapCell: Identifiable {
    let date: Date
    let grams: Double
    let weekIndex: Int   // 0 = oldest, 3 = most recent
    let dayIndex: Int    // 0 = locale first weekday
    let isCurrentWeek: Bool
    var id: Date { date }
}

// MARK: - Guideline comparison row

struct GuidelineComparison: Identifiable {
    let guideline: GuidelineChoice
    let name: String
    let weeklyGrams: Double
    let limitGrams: Double

    var fraction: Double {
        guard limitGrams > 0 else { return 0 }
        return weeklyGrams / limitGrams
    }

    var id: String { guideline.rawValue }
}
