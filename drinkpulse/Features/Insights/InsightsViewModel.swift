import Foundation

@Observable @MainActor final class InsightsViewModel {
    var events: [ConsumptionEvent] = []
    var profile: UserProfile? = nil
    var now: Date = .now
    var period: InsightsPeriod = .week

    // Independent offset per scope — preserved when switching between scopes
    private(set) var weekOffset: Int = 0
    private(set) var monthOffset: Int = 0
    private(set) var yearOffset: Int = 0

    // MARK: - Navigation

    var activeOffset: Int {
        switch period {
        case .week:  return weekOffset
        case .month: return monthOffset
        case .year:  return yearOffset
        }
    }

    var isCurrentPeriod: Bool { activeOffset == 0 }

    var oldestEventDate: Date? { events.map(\.timestamp).min() }

    var minAllowedOffset: Int {
        guard let oldest = oldestEventDate else { return 0 }
        return period.offset(for: oldest, relativeTo: now, calendar: cal)
    }

    func navigatePrev() {
        let next = activeOffset - 1
        guard next >= minAllowedOffset else { return }
        setOffset(next)
    }

    func navigateNext() {
        guard activeOffset < 0 else { return }
        setOffset(activeOffset + 1)
    }

    func jumpToNow() { setOffset(0) }

    private func setOffset(_ value: Int) {
        switch period {
        case .week:  weekOffset = value
        case .month: monthOffset = value
        case .year:  yearOffset = value
        }
    }

    // MARK: - Calendar

    var cal: Calendar { Calendar.current }

    // MARK: - Active date range

    var activeDateRange: ClosedRange<Date> {
        period.dateRange(offset: activeOffset, now: now, calendar: cal)
    }

    var friendlyLabel: String {
        period.friendlyLabel(offset: activeOffset, now: now, calendar: cal)
    }

    var rangeLabel: String {
        period.rangeLabel(offset: activeOffset, now: now, calendar: cal)
    }

    // MARK: - Guideline helpers

    var sex: BiologicalSex { profile?.biologicalSex ?? .male }
    var guidelineChoice: GuidelineChoice { profile?.guidelineChoice ?? .who }

    func limits(for guideline: GuidelineChoice) -> GuidelineLimits {
        if guideline == .custom {
            let weekly = max(profile?.weeklyGoalGrams ?? 100, 1.0)
            return GuidelineLimits(dailyGrams: weekly / 7, weeklyGrams: weekly)
        }
        return guideline.limits(for: sex)
    }

    var effectiveDailyLimitGrams: Double {
        let l = limits(for: guidelineChoice)
        return l.dailyGrams > 0 ? l.dailyGrams : l.weeklyGrams / 7
    }

    // MARK: - Data source

    static var preview: InsightsViewModel {
        let vm = InsightsViewModel()
        vm.events = InsightsDataGenerator.previewEvents()
        vm.profile = UserProfile.preview
        return vm
    }

    func gramsForDay(_ date: Date) -> Double {
        let dayStart = cal.startOfDay(for: date)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }
        return events
            .filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            .reduce(0.0) { $0 + $1.pureAlcoholGrams }
    }

    // MARK: - Period aggregates

    var activeDays: [Date] { cal.days(in: activeDateRange) }

    var periodTotalGrams: Double {
        activeDays.reduce(0) { $0 + gramsForDay($1) }
    }

    var prevPeriodTotalGrams: Double {
        let prevRange = period.dateRange(offset: activeOffset - 1, now: now, calendar: cal)
        return cal.days(in: prevRange).reduce(0) { $0 + gramsForDay($1) }
    }

    var trendFraction: Double {
        guard prevPeriodTotalGrams > 0 else { return 0 }
        return (periodTotalGrams - prevPeriodTotalGrams) / prevPeriodTotalGrams
    }

    // MARK: - Health metrics (all derived from activeDateRange)

    var bingeEpisodes: Int {
        activeDays.filter { gramsForDay($0) >= 60 }.count
    }

    var periodCaloriesKcal: Int { Int(periodTotalGrams * 7) }

    var drinkFreeDays: (count: Int, total: Int) {
        let total = activeDays.count
        let free = activeDays.filter { gramsForDay($0) == 0 }.count
        return (free, total)
    }

    var longestSoberStreak: Int {
        var best = 0
        var run = 0
        for day in activeDays {
            if gramsForDay(day) == 0 { run += 1; best = max(best, run) } else { run = 0 }
        }
        return best
    }

    var heaviestDay: (grams: Double, date: Date)? {
        guard let result = activeDays
            .map({ (gramsForDay($0), $0) })
            .max(by: { $0.0 < $1.0 }),
              result.0 > 0
        else { return nil }
        return (result.0, result.1)
    }

    var periodSpend: Double? {
        let prices = events
            .filter { activeDateRange.contains($0.timestamp) }
            .compactMap(\.price)
        return prices.isEmpty ? nil : prices.reduce(0, +)
    }

    var periodSpendPerDay: Double? {
        guard let spend = periodSpend, activeDays.count > 0 else { return nil }
        return spend / Double(activeDays.count)
    }

    // MARK: - Risk level

    func riskLevel(for grams: Double) -> RiskLevel {
        guard effectiveDailyLimitGrams > 0 else { return .safe }
        return RiskLevel.from(pct: grams / effectiveDailyLimitGrams)
    }

    // MARK: - Guideline comparisons

    private func effectiveDailyLimit(for guideline: GuidelineChoice) -> Double {
        let l = limits(for: guideline)
        return l.dailyGrams > 0 ? l.dailyGrams : l.weeklyGrams / 7
    }

    var guidelineComparisons: [GuidelineComparison] {
        let consumed = periodTotalGrams
        let days = Double(activeDays.count)
        return [GuidelineChoice.who, .uk, .de].map { guideline in
            GuidelineComparison(
                guideline: guideline,
                name: guidelineShortName(guideline),
                consumedGrams: consumed,
                limitGrams: effectiveDailyLimit(for: guideline) * days
            )
        }
    }

    // MARK: - Formatting

    func formattedValue(_ grams: Double) -> String {
        guard let p = profile else { return String(format: "%.0f g", grams) }
        return p.alcoholUnit.formattedValue(grams, guideline: p.guidelineChoice) + " " + p.alcoholUnit.unitLabel
    }

    func formattedSpend(_ amount: Double) -> String {
        let code = profile?.currency ?? "EUR"
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = code
        return fmt.string(from: NSNumber(value: amount)) ?? "\(code) \(String(format: "%.2f", amount))"
    }

    // Backward-compat alias used by existing tests and HealthMetricRow.
    var bingeEpisodesThisMonth: Int { bingeEpisodes }
    var monthCaloriesKcal: Int { periodCaloriesKcal }
    var monthSpend: Double? { periodSpend }

    private func guidelineShortName(_ g: GuidelineChoice) -> String {
        switch g {
        case .who: return String(localized: "insights.guideline.who")
        case .uk:  return String(localized: "insights.guideline.nhs")
        case .de:  return String(localized: "insights.guideline.dhs")
        default:   return g.rawValue.uppercased()
        }
    }
}

// MARK: - Calendar utility

extension Calendar {
    func days(in range: ClosedRange<Date>) -> [Date] {
        var result: [Date] = []
        var current = startOfDay(for: range.lowerBound)
        let end = startOfDay(for: range.upperBound)
        while current <= end {
            result.append(current)
            guard let next = date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return result
    }
}
