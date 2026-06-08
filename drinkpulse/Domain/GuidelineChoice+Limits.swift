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

    /// Resolves the user-facing limits for a profile. Unlike `limits(for:)`,
    /// this accounts for the `.custom` guideline, which carries no built-in
    /// thresholds and instead derives its limits from the user's weekly goal.
    /// The custom goal is clamped to ≥1 g so it can never produce a zero
    /// denominator (which would make every risk fraction read as low risk).
    nonisolated func effectiveLimits(weeklyGoalGrams: Double, for sex: BiologicalSex) -> GuidelineLimits {
        guard self == .custom else { return limits(for: sex) }
        let weekly = max(weeklyGoalGrams, 1.0)
        return GuidelineLimits(dailyGrams: weekly / 7, weeklyGrams: weekly)
    }
}
