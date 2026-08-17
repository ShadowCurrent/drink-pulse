import Foundation

extension GuidelineChoice {
    nonisolated func limits(for sex: BiologicalSex) -> GuidelineLimits {
        switch self {
        case .who:
            return sex == .male
                ? GuidelineLimits(dailyGrams: 20, weeklyGrams: 100)
                : GuidelineLimits(dailyGrams: 10, weeklyGrams: 50)
        case .de:
            return sex == .male
                ? GuidelineLimits(dailyGrams: 24, weeklyGrams: 120)
                : GuidelineLimits(dailyGrams: 12, weeklyGrams: 60)
        case .uk:
            return GuidelineLimits(dailyGrams: 0, weeklyGrams: 112)
        case .us:
            return sex == .male
                ? GuidelineLimits(dailyGrams: 28, weeklyGrams: 196)
                : GuidelineLimits(dailyGrams: 14, weeklyGrams: 98)
        case .au:
            return GuidelineLimits(dailyGrams: 40, weeklyGrams: 100)
        case .ca:
            return sex == .male
                ? GuidelineLimits(dailyGrams: 3 * 13.45, weeklyGrams: 15 * 13.45)
                : GuidelineLimits(dailyGrams: 2 * 13.45, weeklyGrams: 10 * 13.45)
        case .custom:
            return GuidelineLimits(dailyGrams: 0, weeklyGrams: 0)
        }
    }

    nonisolated func effectiveLimits(weeklyGoalGrams: Double, for sex: BiologicalSex) -> GuidelineLimits {
        guard self == .custom else { return limits(for: sex) }
        let weekly = max(weeklyGoalGrams, 1.0)
        return GuidelineLimits(dailyGrams: weekly / 7, weeklyGrams: weekly)
    }
}
