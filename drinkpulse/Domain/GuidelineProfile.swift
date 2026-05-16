import Foundation
import SwiftData

@Model
final class GuidelineProfile {
    var name: String
    var dailyLimitGrams: Double
    var weeklyLimitGrams: Double
    var bingeDrinkingThresholdGrams: Double
    var isCustom: Bool

    init(
        name: String,
        dailyLimitGrams: Double,
        weeklyLimitGrams: Double,
        bingeDrinkingThresholdGrams: Double,
        isCustom: Bool = false
    ) {
        self.name = name
        self.dailyLimitGrams = dailyLimitGrams
        self.weeklyLimitGrams = weeklyLimitGrams
        self.bingeDrinkingThresholdGrams = bingeDrinkingThresholdGrams
        self.isCustom = isCustom
    }
}

extension GuidelineProfile {
    // WHO: ≤20 g/day, ≤100 g/week. Binge: ≥60 g in one occasion.
    static var who: GuidelineProfile {
        GuidelineProfile(name: "WHO", dailyLimitGrams: 20, weeklyLimitGrams: 100,
                         bingeDrinkingThresholdGrams: 60)
    }

    // Germany (DHS): ≤24 g/day (men), ≤168 g/week (men). Using men's thresholds as default.
    static var de: GuidelineProfile {
        GuidelineProfile(name: "DE", dailyLimitGrams: 24, weeklyLimitGrams: 168,
                         bingeDrinkingThresholdGrams: 60)
    }

    // UK (NHS): 14 units/week = 112 g. No safe daily limit stated; daily is 0 to surface weekly.
    static var uk: GuidelineProfile {
        GuidelineProfile(name: "UK", dailyLimitGrams: 0, weeklyLimitGrams: 112,
                         bingeDrinkingThresholdGrams: 60)
    }

    // US (NIAAA): ≤2 standard drinks/day = 28 g, ≤14/week = 196 g. Binge: ≥5 drinks = 70 g.
    static var us: GuidelineProfile {
        GuidelineProfile(name: "US", dailyLimitGrams: 28, weeklyLimitGrams: 196,
                         bingeDrinkingThresholdGrams: 70)
    }

    static var preview: GuidelineProfile { .who }
}
