import Foundation

extension InsightsViewModel {

    // MARK: - Formatting

    func formattedValue(_ grams: Double) -> String {
        guard let p = profile else { return String(format: "%.0f g", grams) }
        return p.alcoholUnit.formattedValue(grams, guideline: p.guidelineChoice) + " " + p.alcoholUnit.unitLabel
    }

    // "consumed / limit unit" in the user's chosen unit (units / standard drinks / g),
    // so the guideline comparison rows match the rest of the app instead of forcing grams.
    func comparisonLabel(_ item: GuidelineComparison) -> String {
        let unit = profile?.alcoholUnit ?? .units
        let consumed = unit.formattedValue(item.consumedGrams, guideline: guidelineChoice)
        let limit    = unit.formattedValue(item.limitGrams, guideline: guidelineChoice)
        return "\(consumed) / \(limit) \(unit.unitLabel)"
    }

    func formattedSpend(_ amount: Double) -> String {
        let code = profile?.currency ?? "EUR"
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = code
        return fmt.string(from: NSNumber(value: amount)) ?? "\(code) \(String(format: "%.2f", amount))"
    }

    // Backward-compat alias used by existing tests and HealthMetricRow.
    var bingeEpisodesThisMonth: Int { bingeEpisodes }
    var monthCaloriesKcal: Int { periodCaloriesKcal }
    var monthSpend: Double? { periodSpend }

    func guidelineShortName(_ g: GuidelineChoice) -> String {
        switch g {
        case .who: return String(localized: "insights.guideline.who")
        case .uk:  return String(localized: "insights.guideline.nhs")
        case .de:  return String(localized: "insights.guideline.dhs")
        default:   return g.rawValue.uppercased()
        }
    }
}
