import Foundation

extension InsightsViewModel {

    // MARK: - Health metrics (all derived from activeDateRange)

    /// The shared alcohol-free / heavy-day rule (plan 0050), started at the first event of any kind.
    var alcoholFreeDayRule: AlcoholFreeDayRule {
        AlcoholFreeDayRule(firstEventDate: oldestEventDate, now: now, calendar: cal)
    }

    var bingeEpisodes: Int {
        AlcoholFreeDayRule.heavyDayCount(in: activeDays, grams: gramsForNormalizedDay)
    }

    var periodCaloriesKcal: Int {
        Int(periodTotalGrams * AlcoholUnit.physicalDensityGramsPerMl / modeDensity * 7)
    }

    var drinkFreeDays: (count: Int, total: Int) {
        alcoholFreeDayRule.alcoholFreeDays(in: activeDays, grams: gramsForNormalizedDay)
    }

    var longestSoberStreak: Int {
        alcoholFreeDayRule.longestAlcoholFreeStreak(in: activeDays, grams: gramsForNormalizedDay)
    }

    var heaviestDay: (grams: Double, date: Date)? {
        guard let result = activeDays
            .map({ (gramsForNormalizedDay($0), $0) })
            .max(by: { $0.0 < $1.0 }),
              result.0 > 0
        else { return nil }
        return (result.0, result.1)
    }

    var periodSpend: Double? {
        let prices = events
            .filter { activeDateRange.contains($0.consumptionDate) }
            .compactMap(\.price)
        return prices.isEmpty ? nil : prices.reduce(0, +)
    }

    var periodSpendPerDay: Double? {
        guard let spend = periodSpend, activeDays.count > 0 else { return nil }
        return spend / Double(activeDays.count)
    }
}
