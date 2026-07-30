import Foundation

// MARK: - Chart point

struct ChartPoint: Identifiable {
    let date: Date
    let grams: Double
    var id: Date { date }

    // Stable, unique, sort-stable categorical key for a date — the single
    // source of truth for the string key `chartXSelection` binds against on
    // `AlcoholAreaChart`'s band-scale x-axis, and the key `InsightsHeroCard`
    // resolves a selection back to a `ChartPoint` through.
    static func key(for date: Date) -> String {
        String(date.timeIntervalSinceReferenceDate)
    }
}

// MARK: - Weekday bar

struct WeekdayBar: Identifiable {
    let weekdayIndex: Int
    let label: String
    let averageGrams: Double
    let riskLevel: RiskLevel
    var id: Int { weekdayIndex }
}

// MARK: - Guideline comparison

struct GuidelineComparison: Identifiable {
    let guideline: GuidelineChoice
    let name: String
    let consumedGrams: Double
    let limitGrams: Double

    var fraction: Double {
        guard limitGrams > 0 else { return 0 }
        return consumedGrams / limitGrams
    }

    var id: String { guideline.rawValue }
}
