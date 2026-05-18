import Foundation

enum RiskLevel: Sendable {
    case safe      // weeklyPct < 0.5
    case caution   // 0.5 ≤ weeklyPct < 1.0
    case exceeded  // weeklyPct ≥ 1.0
}

struct WeekBarEntry: Identifiable {
    var id: Date { day }
    let day: Date
    let label: String
    let grams: Double
    let isToday: Bool
    let isFuture: Bool
}

@Observable @MainActor final class DashboardViewModel {
    var events: [ConsumptionEvent] = []
    var profile: UserProfile? = nil
    var now: Date = .now
    // Drive from UserProfile when first-day-of-week setting is added.
    var weekStartsOnMonday: Bool = true

    // MARK: - Calendar

    private var cal: Calendar {
        var c = Calendar.current
        c.firstWeekday = weekStartsOnMonday ? 2 : 1
        return c
    }

    // MARK: - Guideline limits

    private var limits: GuidelineLimits {
        guard let p = profile else { return GuidelineLimits(dailyGrams: 20, weeklyGrams: 100) }
        if p.guidelineChoice == .custom {
            return GuidelineLimits(dailyGrams: p.weeklyGoalGrams / 7, weeklyGrams: p.weeklyGoalGrams)
        }
        return p.guidelineChoice.limits(for: p.biologicalSex)
    }

    var dailyLimitGrams: Double { limits.dailyGrams }
    var weeklyLimitGrams: Double { limits.weeklyGrams }

    // MARK: - Today

    var todayGrams: Double {
        let start = cal.startOfDay(for: now)
        return events.filter { $0.timestamp >= start }.reduce(0) { $0 + $1.pureAlcoholGrams }
    }

    var todayCaloriesKcal: Int { Int(todayGrams * 7.1) }

    var todayDrinkCount: Int {
        let start = cal.startOfDay(for: now)
        return events.filter { $0.timestamp >= start }.count
    }

    var todaySpend: Double? {
        let start = cal.startOfDay(for: now)
        let prices = events.filter { $0.timestamp >= start }.compactMap(\.price)
        return prices.isEmpty ? nil : prices.reduce(0, +)
    }

    // MARK: - Weekly

    private var weekInterval: DateInterval? {
        cal.dateInterval(of: .weekOfYear, for: cal.startOfDay(for: now))
    }

    var weeklyGrams: Double {
        guard let interval = weekInterval else { return 0 }
        return events
            .filter { $0.timestamp >= interval.start && $0.timestamp < interval.end }
            .reduce(0) { $0 + $1.pureAlcoholGrams }
    }

    var weeklyPct: Double {
        guard weeklyLimitGrams > 0 else { return 0 }
        return weeklyGrams / weeklyLimitGrams
    }

    var riskLevel: RiskLevel {
        if weeklyPct < 0.5 { return .safe }
        if weeklyPct < 1.0 { return .caution }
        return .exceeded
    }

    // MARK: - Week bar chart

    var weekBarData: [WeekBarEntry] {
        guard let interval = weekInterval else { return [] }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        let today = cal.startOfDay(for: now)

        return (0..<7).compactMap { offset -> WeekBarEntry? in
            guard let day = cal.date(byAdding: .day, value: offset, to: interval.start) else { return nil }
            let dayStart = cal.startOfDay(for: day)
            guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return nil }

            let isFuture = dayStart > today
            let isToday = cal.isDate(dayStart, inSameDayAs: today)
            let grams: Double = isFuture ? 0 : events
                .filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
                .reduce(0) { $0 + $1.pureAlcoholGrams }

            return WeekBarEntry(day: dayStart, label: formatter.string(from: dayStart),
                                grams: grams, isToday: isToday, isFuture: isFuture)
        }
    }

    // MARK: - Streaks

    var currentStreakDays: Int {
        if todayGrams > 0 { return 0 }
        if events.isEmpty { return 0 }
        var count = 0
        let today = cal.startOfDay(for: now)
        guard var cursor = cal.date(byAdding: .day, value: -1, to: today) else { return 0 }
        while count <= 365 {
            let s = cal.startOfDay(for: cursor)
            guard let e = cal.date(byAdding: .day, value: 1, to: s) else { break }
            let g = events.filter { $0.timestamp >= s && $0.timestamp < e }
                          .reduce(0) { $0 + $1.pureAlcoholGrams }
            if g > 0 { break }
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    var soberDaysThisMonthDates: [Date] {
        let today = cal.startOfDay(for: now)
        guard let range = cal.range(of: .day, in: .month, for: now) else { return [] }
        return range.compactMap { dayNum -> Date? in
            var comps = cal.dateComponents([.year, .month], from: now)
            comps.day = dayNum
            guard let s = cal.date(from: comps), s <= today,
                  let e = cal.date(byAdding: .day, value: 1, to: s) else { return nil }
            let g = events.filter { $0.timestamp >= s && $0.timestamp < e }
                          .reduce(0) { $0 + $1.pureAlcoholGrams }
            return g == 0 ? s : nil
        }
    }

    var soberDaysThisMonth: Int { soberDaysThisMonthDates.count }

    // MARK: - Greeting

    var greetingText: String {
        let hour = cal.component(.hour, from: now)
        if hour < 12 { return String(localized: "dashboard.greeting.morning") }
        if hour < 18 { return String(localized: "dashboard.greeting.afternoon") }
        return String(localized: "dashboard.greeting.evening")
    }

    // MARK: - Display helpers

    var alcoholUnit: AlcoholUnit { profile?.alcoholUnit ?? .units }
    var guidelineChoice: GuidelineChoice { profile?.guidelineChoice ?? .who }

    var guidelineDisplayName: String {
        switch guidelineChoice {
        case .who:    return "WHO"
        case .de:     return "DHS"
        case .uk:     return "NHS"
        case .us:     return "NIAAA"
        case .custom: return String(localized: "settings.guideline.custom")
        }
    }

    func formattedAlcohol(_ grams: Double) -> String {
        "\(alcoholUnit.formattedValue(grams, guideline: guidelineChoice)) \(alcoholUnit.unitLabel)"
    }

    func formattedSpend(_ amount: Double) -> String {
        let code = profile?.currency ?? "USD"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: NSNumber(value: amount)) ?? "\(code) \(String(format: "%.2f", amount))"
    }
}
