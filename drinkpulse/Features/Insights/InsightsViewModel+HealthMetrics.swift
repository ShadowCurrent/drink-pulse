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

    // `activeDays` deliberately keeps the full week/month grid (so the area
    // chart isn't a stub mid-week/mid-month), but the drink-free X/Y must not
    // count days that have not happened yet — a future empty day is not a
    // drink-free day, and it must not inflate the denominator either. Reads
    // `elapsedDays` (added by quick-260718-kgp for `longestSoberStreak`) for
    // both the numerator and denominator. No-op for past periods and for
    // Year/All-Time (`effectiveDateRange` already clamps those to `now`); it
    // only changes behavior for the *current* week/month.
    var drinkFreeDays: (count: Int, total: Int) {
        let total = elapsedDays.count
        let free = elapsedDays.filter { gramsForNormalizedDay($0) == 0 }.count
        return (free, total)
    }

    var longestSoberStreak: Int {
        var best = 0
        var run = 0
        for day in elapsedDays {
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
            .filter { activeDateRange.contains($0.consumptionDate) }
            .compactMap(\.price)
        return prices.isEmpty ? nil : prices.reduce(0, +)
    }

    var periodSpendPerDay: Double? {
        guard let spend = periodSpend, activeDays.count > 0 else { return nil }
        return spend / Double(activeDays.count)
    }
}
