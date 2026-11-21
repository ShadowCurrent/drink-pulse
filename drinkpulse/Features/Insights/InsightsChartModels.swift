import Foundation

// MARK: - Chart point

/// One point of the area chart. `slot` is the 0-based index in the period and is the chart
/// identity (plan 0046, D0046-9), so switching period morphs the marks instead of cross-fading.
struct ChartPoint: Identifiable {
    let slot: Int
    let date: Date
    let grams: Double
    var id: Int { slot }

    // Categorical axis key of the old area chart; removed with that chart in plan 0046 Task 5.
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
