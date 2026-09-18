import Foundation

nonisolated struct GuidelineLimits: Sendable {
    let dailyGrams: Double
    let weeklyGrams: Double
}

extension GuidelineLimits {
    nonisolated var effectiveDailyGrams: Double {
        dailyGrams > 0 ? dailyGrams : weeklyGrams / 7
    }
}
