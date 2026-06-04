import Foundation

extension GuidelineChoice {
    /// Returns the low-risk drinking limits for the given biological sex.
    /// Sources: WHO, DHS (DE), NHS (UK), NIAAA (US).
    nonisolated func limits(for sex: BiologicalSex) -> GuidelineLimits {
        switch self {
        case .who:
            return sex == .male
                ? GuidelineLimits(dailyGrams: 20, weeklyGrams: 100)
                : GuidelineLimits(dailyGrams: 10, weeklyGrams: 70)
        case .de:
            return sex == .male
                ? GuidelineLimits(dailyGrams: 24, weeklyGrams: 168)
                : GuidelineLimits(dailyGrams: 12, weeklyGrams: 84)
        case .uk:
            // NHS: 14 units/week, both sexes. 1 unit = 10 ml × 0.789 g/ml = 7.89 g → 14 × 7.89 = 110.46 g.
            return GuidelineLimits(dailyGrams: 0, weeklyGrams: 110.46)
        case .us:
            // NIAAA moderate drinking: men ≤2 drinks/day, ≤14/week; women ≤1/day, ≤7/week.
            return sex == .male
                ? GuidelineLimits(dailyGrams: 28, weeklyGrams: 196)
                : GuidelineLimits(dailyGrams: 14, weeklyGrams: 98)
        case .custom:
            return GuidelineLimits(dailyGrams: 0, weeklyGrams: 0)
        }
    }
}
