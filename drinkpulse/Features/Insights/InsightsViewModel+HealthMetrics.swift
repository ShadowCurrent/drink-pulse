import Foundation

extension InsightsViewModel {

    // MARK: - Health metrics (all derived from activeDateRange)

    var bingeEpisodes: Int {
        activeDays.filter { gramsForNormalizedDay($0) >= 60 }.count
    }

    // Calories use physical (0.789) mass, so kcal never shift when the display unit
    // changes the aggregation density. modeDensity is never 0.
    var periodCaloriesKcal: Int {
        Int(periodTotalGrams * AlcoholUnit.physicalDensityGramsPerMl / modeDensity * 7)
    }

    var drinkFreeDays: (count: Int, total: Int) {
        let total = activeDays.count
        let free = activeDays.filter { gramsForNormalizedDay($0) == 0 }.count
        return (free, total)
    }

    var longestSoberStreak: Int {
        var best = 0
        var run = 0
        for day in activeDays {
            if gramsForNormalizedDay(day) == 0 { run += 1; best = max(best, run) } else { run = 0 }
        }
        return best
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
            .filter { activeDateRange.contains($0.timestamp) }
            .compactMap(\.price)
        return prices.isEmpty ? nil : prices.reduce(0, +)
    }

    var periodSpendPerDay: Double? {
        guard let spend = periodSpend, activeDays.count > 0 else { return nil }
        return spend / Double(activeDays.count)
    }
}
