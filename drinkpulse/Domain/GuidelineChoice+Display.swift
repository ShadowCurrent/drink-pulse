import SwiftUI

extension GuidelineChoice {
    var displayName: String {
        switch self {
        case .who:    String(localized: "settings.guideline.who")
        case .de:     String(localized: "settings.guideline.de")
        case .uk:     String(localized: "settings.guideline.uk")
        case .us:     String(localized: "settings.guideline.us")
        case .custom: String(localized: "settings.guideline.custom")
        }
    }

    func thresholdSummary(for sex: BiologicalSex) -> String {
        let l = limits(for: sex)
        if l.dailyGrams == 0 {
            return String(format: String(localized: "settings.guideline.threshold.weekly.nodaily"), l.weeklyGrams)
        }
        return String(format: String(localized: "settings.guideline.threshold.daily_weekly"), l.dailyGrams, l.weeklyGrams)
    }
}
