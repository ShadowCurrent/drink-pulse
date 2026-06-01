import Foundation

enum RiskLevel: Sendable {
    case safe      // pct < 0.5
    case caution   // 0.5 ≤ pct ≤ 1.0
    case exceeded  // pct > 1.0
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
    var calendar: Calendar = .current

    // MARK: - Guideline limits

    private var limits: GuidelineLimits {
        guard let p = profile else { return GuidelineLimits(dailyGrams: 20, weeklyGrams: 100) }
        if p.guidelineChoice == .custom {
            // Clamp to 1 g minimum so a zero custom goal never produces a zero denominator
            // that would make weeklyPct = 0 and riskLevel = .safe regardless of consumption.
            let weekly = max(p.weeklyGoalGrams, 1.0)
            return GuidelineLimits(dailyGrams: weekly / 7, weeklyGrams: weekly)
        }
        return p.guidelineChoice.limits(for: p.biologicalSex)
    }

    var dailyLimitGrams: Double { limits.dailyGrams }
    var weeklyLimitGrams: Double { limits.weeklyGrams }
    var thirtyDayLimitGrams: Double { weeklyLimitGrams * 30 / 7 }
    // UK guideline defines no daily limit (dailyGrams = 0); fall back to weekly / 7.
    var effectiveDailyLimitGrams: Double {
        dailyLimitGrams > 0 ? dailyLimitGrams : weeklyLimitGrams / 7
    }
    // Fraction of today's intake vs effective daily limit. Not clamped — view clamps for arc.
    var todayPct: Double {
        guard effectiveDailyLimitGrams > 0 else { return 0 }
        return todayGrams / effectiveDailyLimitGrams
    }

    var todayRiskLevel: RiskLevel {
        if todayPct < 0.5  { return .safe }
        if todayPct <= 1.0 { return .caution }
        return .exceeded
    }

    // Worst of weekly and daily risk — drives the header badge.
    var effectiveRiskLevel: RiskLevel {
        switch (riskLevel, todayRiskLevel) {
        case (.exceeded, _), (_, .exceeded): return .exceeded
        case (.caution, _),  (_, .caution):  return .caution
        default:                              return .safe
        }
    }

    // MARK: - Today

    var todayGrams: Double {
        let start = calendar.startOfDay(for: now)
        return events.filter { $0.timestamp >= start }.reduce(0) { $0 + $1.pureAlcoholGrams }
    }

    var todayCaloriesKcal: Int { Int(todayGrams * 7.1) }

    var todayDrinkCount: Int {
        let start = calendar.startOfDay(for: now)
        return events.filter { $0.timestamp >= start }.count
    }

    var todaySpend: Double? {
        let start = calendar.startOfDay(for: now)
        let prices = events.filter { $0.timestamp >= start }.compactMap(\.price)
        return prices.isEmpty ? nil : prices.reduce(0, +)
    }

    // MARK: - 30 days

    var thirtyDayGrams: Double {
        guard let start = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now)) else { return 0 }
        return events.filter { $0.timestamp >= start }.reduce(0) { $0 + $1.pureAlcoholGrams }
    }

    // MARK: - Weekly

    // Rolling 7-day window — used for the "7 Days" progress bar and risk level.
    // weekInterval (Mon–Sun) is kept for the bar chart only.
    var sevenDayGrams: Double {
        guard let start = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) else { return 0 }
        return events.filter { $0.timestamp >= start }.reduce(0) { $0 + $1.pureAlcoholGrams }
    }

    private var weekInterval: DateInterval? {
        calendar.dateInterval(of: .weekOfYear, for: calendar.startOfDay(for: now))
    }

    // Mon–Sun window — used only by weekBarData chart.
    var weeklyGrams: Double {
        guard let interval = weekInterval else { return 0 }
        return events
            .filter { $0.timestamp >= interval.start && $0.timestamp < interval.end }
            .reduce(0) { $0 + $1.pureAlcoholGrams }
    }

    var weeklyPct: Double {
        guard weeklyLimitGrams > 0 else { return 0 }
        return sevenDayGrams / weeklyLimitGrams
    }

    var riskLevel: RiskLevel {
        if weeklyPct < 0.5  { return .safe }
        if weeklyPct <= 1.0 { return .caution }
        return .exceeded
    }

    // MARK: - Week bar chart

    var weekBarData: [WeekBarEntry] {
        guard let interval = weekInterval else { return [] }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        let today = calendar.startOfDay(for: now)

        return (0..<7).compactMap { offset -> WeekBarEntry? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: interval.start) else { return nil }
            let dayStart = calendar.startOfDay(for: day)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }

            let isFuture = dayStart > today
            let isToday = calendar.isDate(dayStart, inSameDayAs: today)
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
        let today = calendar.startOfDay(for: now)
        guard var cursor = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        while count <= 365 {
            let s = calendar.startOfDay(for: cursor)
            guard let e = calendar.date(byAdding: .day, value: 1, to: s) else { break }
            let g = events.filter { $0.timestamp >= s && $0.timestamp < e }
                          .reduce(0) { $0 + $1.pureAlcoholGrams }
            if g > 0 { break }
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    var soberDaysThisMonthDates: [Date] {
        // No events means no tracking baseline — nothing meaningful to count.
        guard let earliest = events.min(by: { $0.timestamp < $1.timestamp }) else { return [] }
        let today = calendar.startOfDay(for: now)
        let firstTrackedDay = calendar.startOfDay(for: earliest.timestamp)
        guard let range = calendar.range(of: .day, in: .month, for: now) else { return [] }
        var monthStartComps = calendar.dateComponents([.year, .month], from: now)
        monthStartComps.day = 1
        let monthStart = calendar.date(from: monthStartComps) ?? today
        // Don't count days before the user's first ever entry.
        let countFrom = max(monthStart, firstTrackedDay)
        return range.compactMap { dayNum -> Date? in
            var comps = calendar.dateComponents([.year, .month], from: now)
            comps.day = dayNum
            guard let s = calendar.date(from: comps), s >= countFrom, s <= today,
                  let e = calendar.date(byAdding: .day, value: 1, to: s) else { return nil }
            let g = events.filter { $0.timestamp >= s && $0.timestamp < e }
                          .reduce(0) { $0 + $1.pureAlcoholGrams }
            return g == 0 ? s : nil
        }
    }

    var soberDaysThisMonth: Int { soberDaysThisMonthDates.count }

    // MARK: - Greeting

    var greetingText: String {
        let hour = calendar.component(.hour, from: now)
        if hour < 12 { return String(localized: "dashboard.greeting.morning") }
        if hour < 18 { return String(localized: "dashboard.greeting.afternoon") }
        return String(localized: "dashboard.greeting.evening")
    }

    // MARK: - Display helpers

    var alcoholUnit: AlcoholUnit { profile?.alcoholUnit ?? .units }
    var guidelineChoice: GuidelineChoice { profile?.guidelineChoice ?? .who }

    var guidelineDisplayName: String { guidelineChoice.displayName }

    func formattedAlcohol(_ grams: Double) -> String {
        "\(alcoholUnit.formattedValue(grams, guideline: guidelineChoice)) \(alcoholUnit.unitLabel)"
    }

    // Number only (no unit label) — used for "X / Y unit" displays.
    func formattedNumber(_ grams: Double) -> String {
        alcoholUnit.formattedValue(grams, guideline: guidelineChoice)
    }

    func formattedSpend(_ amount: Double) -> String {
        let code = profile?.currency ?? "USD"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: NSNumber(value: amount)) ?? "\(code) \(String(format: "%.2f", amount))"
    }
}
