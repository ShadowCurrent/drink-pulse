import Foundation

@Observable @MainActor final class InsightsViewModel {
    var events: [ConsumptionEvent] = []
    var profile: UserProfile? = nil
    var now: Date = .now
    var period: InsightsPeriod = .week

    // MARK: - Calendar

    var cal: Calendar { Calendar.current }

    // MARK: - Guideline helpers

    var sex: BiologicalSex { profile?.biologicalSex ?? .male }

    var guidelineChoice: GuidelineChoice { profile?.guidelineChoice ?? .who }

    private func limits(for guideline: GuidelineChoice) -> GuidelineLimits {
        if guideline == .custom {
            let weekly = max(profile?.weeklyGoalGrams ?? 100, 1.0)
            return GuidelineLimits(dailyGrams: weekly / 7, weeklyGrams: weekly)
        }
        return guideline.limits(for: sex)
    }

    private var effectiveDailyLimitGrams: Double {
        let l = limits(for: guidelineChoice)
        return l.dailyGrams > 0 ? l.dailyGrams : l.weeklyGrams / 7
    }

    // MARK: - Period date range

    private var range: ClosedRange<Date> { period.dateRange(now: now, calendar: cal) }

    private var periodEvents: [ConsumptionEvent] {
        events.filter { range.contains($0.timestamp) }
    }

    // MARK: - Area chart (seriesData)

    var seriesData: [ChartPoint] {
        switch period {
        case .week:  return bucketByDay(in: range)
        case .month: return bucketByWeek(in: range)
        case .year:  return bucketByMonth(in: range)
        }
    }

    private func bucketByDay(in range: ClosedRange<Date>) -> [ChartPoint] {
        let days = cal.days(in: range)
        return days.map { day in
            let next = cal.date(byAdding: .day, value: 1, to: day) ?? day
            let g = events.filter { $0.timestamp >= day && $0.timestamp < next }
                          .reduce(0) { $0 + $1.pureAlcoholGrams }
            return ChartPoint(date: day, grams: g)
        }
    }

    private func bucketByWeek(in range: ClosedRange<Date>) -> [ChartPoint] {
        var buckets: [Date: Double] = [:]
        for event in periodEvents {
            guard let weekStart = cal.dateInterval(of: .weekOfYear, for: event.timestamp)?.start else { continue }
            buckets[weekStart, default: 0] += event.pureAlcoholGrams
        }
        return buckets.map { ChartPoint(date: $0.key, grams: $0.value) }
                      .sorted { $0.date < $1.date }
    }

    private func bucketByMonth(in range: ClosedRange<Date>) -> [ChartPoint] {
        var buckets: [Date: Double] = [:]
        for event in periodEvents {
            guard let monthStart = cal.dateInterval(of: .month, for: event.timestamp)?.start else { continue }
            buckets[monthStart, default: 0] += event.pureAlcoholGrams
        }
        return buckets.map { ChartPoint(date: $0.key, grams: $0.value) }
                      .sorted { $0.date < $1.date }
    }

    // MARK: - Weekday averages

    var weekdayAverages: [WeekdayBar] {
        let firstDay = cal.firstWeekday  // 1=Sun, 2=Mon, ...
        let days = cal.days(in: range)
        // Count how many times each column-weekday appears in the range
        var counts = [Int: Int]()
        var sums   = [Int: Double]()
        for day in days {
            let col = columnIndex(for: day, firstDay: firstDay)
            counts[col, default: 0] += 1
        }
        for event in periodEvents {
            let col = columnIndex(for: event.timestamp, firstDay: firstDay)
            sums[col, default: 0] += event.pureAlcoholGrams
        }
        return (0..<7).map { col in
            let weekday = ((firstDay - 1 + col) % 7) + 1  // 1-based weekday
            let avg = counts[col].map { Double(sums[col, default: 0]) / Double($0) } ?? 0
            return WeekdayBar(
                weekdayIndex: col,
                label: shortWeekdayLabel(weekday: weekday),
                averageGrams: avg,
                riskLevel: riskLevel(for: avg)
            )
        }
    }

    private func riskLevel(for grams: Double) -> RiskLevel {
        guard effectiveDailyLimitGrams > 0 else { return .safe }
        let pct = grams / effectiveDailyLimitGrams
        if pct < 0.5 { return .safe }
        if pct < 1.0 { return .caution }
        return .exceeded
    }

    // MARK: - Health metrics

    var currentRiskLevel: RiskLevel {
        let l = limits(for: guidelineChoice)
        let weekly = l.weeklyGrams > 0 ? l.weeklyGrams : 1
        let pct = sevenDayGrams / weekly
        if pct < 0.5 { return .safe }
        if pct < 1.0 { return .caution }
        return .exceeded
    }

    var sevenDayGrams: Double {
        guard let start = cal.date(byAdding: .day, value: -7, to: cal.startOfDay(for: now)) else { return 0 }
        return events.filter { $0.timestamp >= start }.reduce(0) { $0 + $1.pureAlcoholGrams }
    }

    var monthCaloriesKcal: Int {
        guard let start = cal.date(byAdding: .day, value: -29, to: cal.startOfDay(for: now)) else { return 0 }
        let g = events.filter { $0.timestamp >= start }.reduce(0) { $0 + $1.pureAlcoholGrams }
        return Int(g * 7.1)
    }

    var monthSpend: Double? {
        guard let start = cal.date(byAdding: .day, value: -29, to: cal.startOfDay(for: now)) else { return nil }
        let prices = events.filter { $0.timestamp >= start }.compactMap(\.price)
        return prices.isEmpty ? nil : prices.reduce(0, +)
    }

    // MARK: - Guideline comparisons

    var guidelineComparisons: [GuidelineComparison] {
        let weekly = sevenDayGrams
        return [GuidelineChoice.who, .uk, .de].map { guideline in
            GuidelineComparison(
                guideline: guideline,
                name: guidelineShortName(guideline),
                weeklyGrams: weekly,
                limitGrams: limits(for: guideline).weeklyGrams
            )
        }
    }

    func formattedSpend(_ amount: Double) -> String {
        let code = profile?.currency ?? "USD"
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = code
        return fmt.string(from: NSNumber(value: amount)) ?? "\(code) \(String(format: "%.2f", amount))"
    }

    private func guidelineShortName(_ g: GuidelineChoice) -> String {
        switch g {
        case .who: return String(localized: "insights.guideline.who")
        case .uk:  return String(localized: "insights.guideline.nhs")
        case .de:  return String(localized: "insights.guideline.dhs")
        default:   return g.rawValue.uppercased()
        }
    }

    // MARK: - Private helpers

    private func columnIndex(for date: Date, firstDay: Int) -> Int {
        let weekday = cal.component(.weekday, from: date)  // 1=Sun ... 7=Sat
        return (weekday - firstDay + 7) % 7
    }

    private func shortWeekdayLabel(weekday: Int) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale.current
        guard weekday >= 1, weekday <= 7 else { return "" }
        return fmt.shortStandaloneWeekdaySymbols[weekday - 1]
    }
}

// MARK: - Calendar extension

private extension Calendar {
    func days(in range: ClosedRange<Date>) -> [Date] {
        var days: [Date] = []
        var current = startOfDay(for: range.lowerBound)
        let end = startOfDay(for: range.upperBound)
        while current <= end {
            days.append(current)
            guard let next = date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return days
    }
}
