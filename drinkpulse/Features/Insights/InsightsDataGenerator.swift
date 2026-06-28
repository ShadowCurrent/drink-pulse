import Foundation
import SwiftData

// Seeded per-day generator for historical alcohol data used when no real
// SwiftData events exist for a given day. All past dates from Jan 1 2023
// produce consistent, plausible values. Returns nil for today, the future,
// and dates before the start date.
struct InsightsDataGenerator {

    private static let startDate: Date = {
        var c = DateComponents()
        c.year = 2023; c.month = 1; c.day = 1
        return Calendar.current.date(from: c) ?? .distantPast
    }()

    static func gramsForDate(_ date: Date) -> Int? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let day = cal.startOfDay(for: date)
        guard day < today, day >= startDate else { return nil }

        let comps = cal.dateComponents([.year, .month, .day, .weekday], from: day)
        guard let year = comps.year, let month = comps.month,
              let dayOfMonth = comps.day, let weekday = comps.weekday else { return nil }

        let seed = UInt64(year) &* 10000 &+ UInt64(month) &* 100 &+ UInt64(dayOfMonth)
        let r1 = pseudoRandom(seed)
        let r2 = pseudoRandom(seed &+ 1)

        // Dry-day probability increases in more recent years (user is improving)
        let dryProbability: Double
        switch year {
        case 2023: dryProbability = 0.28
        case 2024: dryProbability = 0.38
        case 2025: dryProbability = 0.50
        default:   dryProbability = 0.60
        }
        if r1 < dryProbability { return 0 }

        // Day-of-week: weekday=1(Sun)..7(Sat)
        let dowMultiplier: Double
        switch weekday {
        case 7:  dowMultiplier = 1.8   // Sat
        case 6:  dowMultiplier = 1.6   // Fri
        case 1:  dowMultiplier = 1.3   // Sun
        default: dowMultiplier = 0.7
        }

        // Seasonal: summer and December are heavier
        let seasonMultiplier: Double
        switch month {
        case 6, 7, 8: seasonMultiplier = 1.25
        case 12:       seasonMultiplier = 1.35
        case 11, 1:    seasonMultiplier = 1.10
        default:       seasonMultiplier = 1.00
        }

        // Long-term trend: older = more drinking
        let trendMultiplier: Double
        switch year {
        case 2023: trendMultiplier = 1.35
        case 2024: trendMultiplier = 1.20
        case 2025: trendMultiplier = 1.08
        default:   trendMultiplier = 1.00
        }

        let base = 15.0 + r2 * 40.0
        return max(0, Int((base * dowMultiplier * seasonMultiplier * trendMultiplier).rounded()))
    }

    // Knuth MMIX LCG step — deterministic, no stdlib random state
    private static func pseudoRandom(_ seed: UInt64) -> Double {
        var x = seed &* 6364136223846793005 &+ 1442695040888963407
        x ^= x >> 30
        return Double(x) / Double(UInt64.max)
    }

    // Returns a batch of ConsumptionEvent objects suitable for populating
    // InsightsViewModel.preview. Never call from production code paths.
    static func previewEvents(days: Int = 400) -> [ConsumptionEvent] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var events: [ConsumptionEvent] = []
        for offset in 1...days {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today),
                  let grams = gramsForDate(day), grams > 0
            else { continue }
            let abv = 0.05
            let volumeMl = Double(grams) / (abv * 0.8)
            let ts = cal.date(byAdding: .hour, value: 20, to: day) ?? day
            events.append(ConsumptionEvent(
                timestamp: ts, volumeMl: volumeMl, abv: abv,
                category: .beer, icon: "🍺"
            ))
        }
        return events
    }
}
