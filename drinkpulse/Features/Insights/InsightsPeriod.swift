import Foundation

// MARK: - Period scope

enum InsightsPeriod: String, CaseIterable, Hashable {
    case week, month, year

    var localizedLabel: String {
        switch self {
        case .week:  return String(localized: "insights.period.week")
        case .month: return String(localized: "insights.period.month")
        case .year:  return String(localized: "insights.period.year")
        }
    }

    // Maximum backward navigation (negative offsets)
    var minOffset: Int {
        switch self {
        case .week:  return -156  // ~3 years of weeks
        case .month: return -35
        case .year:  return -3    // back to 2023
        }
    }

    func dateRange(offset: Int, now: Date, calendar: Calendar) -> ClosedRange<Date> {
        switch self {
        case .week:
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
                return now...now
            }
            guard let start = calendar.date(byAdding: .weekOfYear, value: offset, to: weekInterval.start) else {
                return now...now
            }
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
            return start...endOfDay

        case .month:
            let base = calendar.dateComponents([.year, .month], from: now)
            guard let baseStart = calendar.date(from: base),
                  let shifted = calendar.date(byAdding: .month, value: offset, to: baseStart),
                  let interval = calendar.dateInterval(of: .month, for: shifted)
            else { return now...now }
            let endOfDay = calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end
            return interval.start...endOfDay

        case .year:
            let base = calendar.dateComponents([.year], from: now)
            guard let baseStart = calendar.date(from: base),
                  let shifted = calendar.date(byAdding: .year, value: offset, to: baseStart),
                  let interval = calendar.dateInterval(of: .year, for: shifted)
            else { return now...now }
            let endOfDay = calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end
            return interval.start...endOfDay
        }
    }

    func friendlyLabel(offset: Int, now: Date, calendar: Calendar) -> String {
        switch self {
        case .week:
            switch offset {
            case 0:  return String(localized: "insights.nav.thisWeek")
            case -1: return String(localized: "insights.nav.lastWeek")
            default: return String(format: String(localized: "insights.nav.weeksAgo"), -offset)
            }
        case .month:
            switch offset {
            case 0:  return String(localized: "insights.nav.thisMonth")
            case -1: return String(localized: "insights.nav.lastMonth")
            default:
                let range = dateRange(offset: offset, now: now, calendar: calendar)
                return range.lowerBound.formatted(.dateTime.month(.wide).year())
            }
        case .year:
            switch offset {
            case 0:  return String(localized: "insights.nav.thisYear")
            case -1: return String(localized: "insights.nav.lastYear")
            default: return String(format: String(localized: "insights.nav.yearsAgo"), -offset)
            }
        }
    }

    func rangeLabel(offset: Int, now: Date, calendar: Calendar) -> String {
        let range = dateRange(offset: offset, now: now, calendar: calendar)
        switch self {
        case .week:
            let s = range.lowerBound.formatted(.dateTime.month(.abbreviated).day())
            let e = range.upperBound.formatted(.dateTime.month(.abbreviated).day().year())
            return "\(s) – \(e)"
        case .month:
            return range.lowerBound.formatted(.dateTime.month(.wide).year())
        case .year:
            return range.lowerBound.formatted(.dateTime.year())
        }
    }
}

// MARK: - Chart point

struct ChartPoint: Identifiable {
    let date: Date
    let grams: Double
    var id: Date { date }
}

// MARK: - Weekday bar

struct WeekdayBar: Identifiable {
    let weekdayIndex: Int
    let label: String
    let averageGrams: Double
    let riskLevel: RiskLevel
    var id: Int { weekdayIndex }
}

// MARK: - Heatmap cell

struct HeatmapCell: Identifiable {
    let date: Date
    let grams: Double
    let weekIndex: Int
    let dayIndex: Int
    let isCurrentWeek: Bool
    let isFuture: Bool
    var id: Date { date }
}

// MARK: - Guideline comparison

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
