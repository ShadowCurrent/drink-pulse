import Foundation
import SwiftData

nonisolated struct InsightsDataGenerator {

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

        let dryProbability: Double
        switch year {
        case 2023: dryProbability = 0.28
        case 2024: dryProbability = 0.38
        case 2025: dryProbability = 0.50
        default:   dryProbability = 0.60
        }
        if r1 < dryProbability { return 0 }

        let dowMultiplier: Double
        switch weekday {
        case 7:  dowMultiplier = 1.8
        case 6:  dowMultiplier = 1.6
        case 1:  dowMultiplier = 1.3
        default: dowMultiplier = 0.7
        }

        let seasonMultiplier: Double
        switch month {
        case 6, 7, 8: seasonMultiplier = 1.25
        case 12:       seasonMultiplier = 1.35
        case 11, 1:    seasonMultiplier = 1.10
        default:       seasonMultiplier = 1.00
        }

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

    private static func pseudoRandom(_ seed: UInt64) -> Double {
        var x = seed &* 6364136223846793005 &+ 1442695040888963407
        x ^= x >> 30
        return Double(x) / Double(UInt64.max)
    }

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
                consumptionDate: ts, volumeMl: volumeMl, abv: abv,
                category: .beer, icon: "🍺"
            ))
        }
        return events
    }
}
