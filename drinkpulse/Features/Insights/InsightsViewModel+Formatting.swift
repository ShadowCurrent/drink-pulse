import Foundation

extension InsightsViewModel {

    // MARK: - Formatting

    func formattedValue(_ grams: Double) -> String {
        guard let p = profile else { return String(format: "%.0f g", grams) }
        let g = p.guidelineChoice
        return p.alcoholUnit.formattedValue(grams, guideline: g) + " " + p.alcoholUnit.unitLabel(for: g)
    }

    /// Grams per one displayed unit — divides gram-valued chart series so axes
    /// read in the user's chosen unit. 1.0 in grams mode (identity).
    var displayUnitDivisor: Double {
        guard let p = profile else { return 1.0 }
        return p.alcoholUnit.gramsPerUnit(for: p.guidelineChoice)
    }

    /// Short unit label for the user's chosen unit/guideline ("units", "std drinks", "g").
    var displayUnitLabel: String {
        let unit = profile?.alcoholUnit ?? .standardDrinks
        return unit.unitLabel(for: guidelineChoice)
    }

    // "consumed / limit unit" in the user's chosen unit (standard drinks / g),
    // so the guideline comparison rows match the rest of the app instead of forcing grams.
    func comparisonLabel(_ item: GuidelineComparison) -> String {
        let unit = profile?.alcoholUnit ?? .standardDrinks
        let consumed = unit.formattedValue(item.consumedGrams, guideline: guidelineChoice)
        let limit    = unit.formattedValue(item.limitGrams, guideline: guidelineChoice)
        return "\(consumed) / \(limit) \(unit.unitLabel(for: guidelineChoice))"
    }

    func formattedSpend(_ amount: Double) -> String {
        let code = profile?.currency ?? "EUR"
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = code
        return fmt.string(from: NSNumber(value: amount)) ?? "\(code) \(String(format: "%.2f", amount))"
    }

    // Backward-compat aliases used by existing tests.
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
