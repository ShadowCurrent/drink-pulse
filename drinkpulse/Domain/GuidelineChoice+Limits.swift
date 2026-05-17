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
            // NHS: identical limits for both sexes, no daily threshold defined.
            return GuidelineLimits(dailyGrams: 0, weeklyGrams: 112)
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
