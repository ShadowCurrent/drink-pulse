import Foundation

/// Caption of the dashed limit rule on the This Week and Insights area charts (plan 0046
/// review). The rule sits at the effective daily limit; for a guideline without a daily limit
/// (UK) that value is weekly / 7, so it reads as a daily average, as the Today hero
/// copy does.
enum LimitRuleCaption {
    static func text(dailyLimitGrams: Double) -> String {
        dailyLimitGrams > 0
            ? String(localized: "dashboard.limit.caption")
            : String(localized: "dashboard.limit.captionAverage")
    }
}
