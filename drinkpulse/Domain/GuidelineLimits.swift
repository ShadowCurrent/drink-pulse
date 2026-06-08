import Foundation

struct GuidelineLimits {
    /// 0 means the guideline defines no daily limit.
    let dailyGrams: Double
    let weeklyGrams: Double
}

extension GuidelineLimits {
    /// Daily limit to compare a single day against. Guidelines with no daily
    /// limit (UK: `dailyGrams == 0`) fall back to an even split of the weekly
    /// limit. Centralises the fallback so call sites can't get it wrong.
    var effectiveDailyGrams: Double {
        dailyGrams > 0 ? dailyGrams : weeklyGrams / 7
    }
}
