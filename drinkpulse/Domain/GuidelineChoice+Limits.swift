import Foundation

extension GuidelineChoice {
    /// Returns the low-risk drinking limits for the given biological sex.
    ///
    /// All values are physical grams of pure alcohol (density 0.789 g/ml).
    ///
    /// Weekly / daily relationship varies by guideline:
    /// - WHO, DE: weekly = daily × 5 (assumes 2 alcohol-free days per week).
    /// - US (NIAAA): weekly = daily × 7 (no assumed alcohol-free days).
    /// - UK (NHS): weekly is an independent published value (14 units); no daily limit.
    /// - AU (NHMRC 2020): both daily and weekly are independent published caps
    ///   (≤4 std drinks/day and ≤10/week; 1 AU std drink = 10 g).
    /// - CA (Health Canada): weekly = daily × 5 (same 2-free-day pattern as WHO/DE),
    ///   but kept as an independent stored value because AU proves ×5 is not universal.
    ///
    /// Sources: WHO; DHS (DE); NHS (UK); NIAAA (US); NHMRC 2020 (AU);
    ///          Health Canada LRDG-2011 (CA, date modified 2025-03-25).
    nonisolated func limits(for sex: BiologicalSex) -> GuidelineLimits {
        switch self {
        case .who:
            // WHO: 2 alcohol-free days assumed → weekly = daily × 5.
            // Male: 20 × 5 = 100 g; female: 10 × 5 = 50 g.
            return sex == .male
                ? GuidelineLimits(dailyGrams: 20, weeklyGrams: 100)
                : GuidelineLimits(dailyGrams: 10, weeklyGrams: 50)
        case .de:
            // DHS: same 2-free-day convention as WHO → weekly = daily × 5.
            // Male: 24 × 5 = 120 g; female: 12 × 5 = 60 g.
            return sex == .male
                ? GuidelineLimits(dailyGrams: 24, weeklyGrams: 120)
                : GuidelineLimits(dailyGrams: 12, weeklyGrams: 60)
        case .uk:
            // NHS: 14 units/week, both sexes. 1 UK unit = 8.0 g (10 ml × 0.8 display
            // density) → 14 × 8.0 = 112 g. No daily limit (sentinel 0).
            // See plan-0025 / ADR density-by-display-unit.
            return GuidelineLimits(dailyGrams: 0, weeklyGrams: 112)
        case .us:
            // NIAAA: no assumed alcohol-free days → weekly = daily × 7.
            // Male: 28 × 7 = 196 g; female: 14 × 7 = 98 g.
            return sex == .male
                ? GuidelineLimits(dailyGrams: 28, weeklyGrams: 196)
                : GuidelineLimits(dailyGrams: 14, weeklyGrams: 98)
        case .au:
            // NHMRC 2020: ≤4 std drinks/day and ≤10/week. 1 AU std drink = 10 g.
            // Both limits are independent published values (40 g/day, 100 g/week).
            // Same limits for both sexes.
            return GuidelineLimits(dailyGrams: 40, weeklyGrams: 100)
        case .ca:
            // Health Canada LRDG-2011 (page updated 2025-03-25; still LRDG-2011, not CCSA-2023).
            // 1 CA standard drink = 13.45 g (341 ml × 5% × 0.789 = 13.45 g).
            // Male: 3/day, 15/week → 3 × 13.45 = 40.35 g/day, 15 × 13.45 = 201.75 g/week.
            // Female: 2/day, 10/week → 2 × 13.45 = 26.9 g/day, 10 × 13.45 = 134.5 g/week.
            // Weekly follows daily × 5 pattern, but stored independently (AU breaks the ×5 rule).
            return sex == .male
                ? GuidelineLimits(dailyGrams: 3 * 13.45, weeklyGrams: 15 * 13.45)
                : GuidelineLimits(dailyGrams: 2 * 13.45, weeklyGrams: 10 * 13.45)
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
