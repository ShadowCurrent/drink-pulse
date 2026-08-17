import Foundation

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
        return p.guidelineChoice.effectiveLimits(weeklyGoalGrams: p.weeklyGoalGrams, for: p.biologicalSex)
    }

    var dailyLimitGrams: Double { limits.dailyGrams }
    var weeklyLimitGrams: Double { limits.weeklyGrams }
    var thirtyDayLimitGrams: Double { weeklyLimitGrams * 30 / 7 }
    var effectiveDailyLimitGrams: Double { limits.effectiveDailyGrams }

    var modeDensity: Double { alcoholUnit.density(for: guidelineChoice) }

    func fraction(consumedGrams: Double, limitGrams: Double) -> Double {
        guard limitGrams > 0 else { return 0 }
        return consumedGrams / limitGrams
    }

    func riskLevel(consumedGrams: Double, limitGrams: Double) -> RiskLevel {
        RiskLevel.from(pct: fraction(consumedGrams: consumedGrams, limitGrams: limitGrams))
    }

    var todayPct: Double { fraction(consumedGrams: todayGrams, limitGrams: effectiveDailyLimitGrams) }

    var todayRiskLevel: RiskLevel { RiskLevel.from(pct: todayPct) }

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
        return events.filter { $0.consumptionDate >= start }.reduce(0) { $0 + $1.alcoholGrams(density: modeDensity) }
    }

    func physicalGrams(_ modeMass: Double) -> Double {
        modeMass * AlcoholUnit.physicalDensityGramsPerMl / modeDensity
    }

    var todayCaloriesKcal: Int { Int(physicalGrams(todayGrams) * 7.1) }

    var todayDrinkCount: Int {
        let start = calendar.startOfDay(for: now)
        return events.filter { $0.consumptionDate >= start }.count
    }

    var todaySpend: Double? {
        let start = calendar.startOfDay(for: now)
        let prices = events.filter { $0.consumptionDate >= start }.compactMap(\.price)
        return prices.isEmpty ? nil : prices.reduce(0, +)
    }

    // MARK: - 30 days

    var thirtyDayGrams: Double {
        guard let start = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now)) else { return 0 }
        return events.filter { $0.consumptionDate >= start }.reduce(0) { $0 + $1.alcoholGrams(density: modeDensity) }
    }

    // MARK: - Weekly

    var sevenDayGrams: Double {
        guard let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) else { return 0 }
        return events.filter { $0.consumptionDate >= start }.reduce(0) { $0 + $1.alcoholGrams(density: modeDensity) }
    }

    private var weekInterval: DateInterval? {
        calendar.dateInterval(of: .weekOfYear, for: calendar.startOfDay(for: now))
    }

    var weeklyGrams: Double {
        guard let interval = weekInterval else { return 0 }
        return events
            .filter { $0.consumptionDate >= interval.start && $0.consumptionDate < interval.end }
            .reduce(0) { $0 + $1.alcoholGrams(density: modeDensity) }
    }

    var weeklyPct: Double {
        guard weeklyLimitGrams > 0 else { return 0 }
        return sevenDayGrams / weeklyLimitGrams
    }

    var riskLevel: RiskLevel { RiskLevel.from(pct: weeklyPct) }

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
                .filter { $0.consumptionDate >= dayStart && $0.consumptionDate < dayEnd }
                .reduce(0) { $0 + $1.alcoholGrams(density: modeDensity) }

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
            let g = events.filter { $0.consumptionDate >= s && $0.consumptionDate < e }
                          .reduce(0) { $0 + $1.alcoholGrams(density: modeDensity) }
            if g > 0 { break }
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    var soberDaysThisMonthDates: [Date] {
        guard let earliest = events.min(by: { $0.consumptionDate < $1.consumptionDate }) else { return [] }
        let today = calendar.startOfDay(for: now)
        let firstTrackedDay = calendar.startOfDay(for: earliest.consumptionDate)
        guard let range = calendar.range(of: .day, in: .month, for: now) else { return [] }
        var monthStartComps = calendar.dateComponents([.year, .month], from: now)
        monthStartComps.day = 1
        let monthStart = calendar.date(from: monthStartComps) ?? today
        let countFrom = max(monthStart, firstTrackedDay)
        return range.compactMap { dayNum -> Date? in
            var comps = calendar.dateComponents([.year, .month], from: now)
            comps.day = dayNum
            guard let s = calendar.date(from: comps), s >= countFrom, s <= today,
                  let e = calendar.date(byAdding: .day, value: 1, to: s) else { return nil }
            let g = events.filter { $0.consumptionDate >= s && $0.consumptionDate < e }
                          .reduce(0) { $0 + $1.alcoholGrams(density: modeDensity) }
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

    var alcoholUnit: AlcoholUnit { profile?.alcoholUnit ?? .standardDrinks }
    var guidelineChoice: GuidelineChoice { profile?.guidelineChoice ?? .who }

    var guidelineDisplayName: String { guidelineChoice.displayName }

    var unitLabel: String { alcoholUnit.unitLabel(for: guidelineChoice) }

    func formattedAlcohol(_ grams: Double) -> String {
        "\(alcoholUnit.formattedValue(grams, guideline: guidelineChoice)) \(unitLabel)"
    }

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
