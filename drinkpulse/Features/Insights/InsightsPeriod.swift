import Foundation

// MARK: - Period scope

enum InsightsPeriod: String, CaseIterable, Hashable {
    case week, month, year, allTime

    var localizedLabel: String {
        switch self {
        case .week:    return String(localized: "insights.period.week")
        case .month:   return String(localized: "insights.period.month")
        case .year:    return String(localized: "insights.period.year")
        case .allTime: return String(localized: "insights.period.allTime")
        }
    }

    /// Returns how many periods `date` is behind `now` (≤ 0).
    /// E.g. -2 means the date falls two periods before the current one.
    func offset(for date: Date, relativeTo now: Date, calendar: Calendar) -> Int {
        switch self {
        case .week:
            guard let eventWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start,
                  let nowWeek   = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            else { return 0 }
            return calendar.dateComponents([.weekOfYear], from: nowWeek, to: eventWeek).weekOfYear ?? 0
        case .month:
            let eComps = calendar.dateComponents([.year, .month], from: date)
            let nComps = calendar.dateComponents([.year, .month], from: now)
            guard let eStart = calendar.date(from: eComps),
                  let nStart  = calendar.date(from: nComps) else { return 0 }
            return calendar.dateComponents([.month], from: nStart, to: eStart).month ?? 0
        case .year:
            return calendar.component(.year, from: date) - calendar.component(.year, from: now)
        case .allTime:
            // All-time is a single fixed range with no offset navigation.
            return 0
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

        case .allTime:
            // Range depends on the oldest event, which lives in the view model.
            // The VM overrides `activeDateRange` for this case; this is a safe fallback.
            return now...now
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
        case .allTime:
            return String(localized: "insights.nav.allTime")
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
        case .allTime:
            // Overridden by the view model (oldest event → now).
            return ""
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

// MARK: - Guideline comparison

struct GuidelineComparison: Identifiable {
    let guideline: GuidelineChoice
    let name: String
    let consumedGrams: Double
    let limitGrams: Double

    var fraction: Double {
        guard limitGrams > 0 else { return 0 }
        return consumedGrams / limitGrams
    }

    var id: String { guideline.rawValue }
}
