import Foundation

extension InsightsViewModel {

    // MARK: - Formatting

    func formattedValue(_ grams: Double) -> String {
        guard let p = profile else { return String(format: "%.0f g", grams) }
        let g = p.guidelineChoice
        return p.alcoholUnit.formattedValue(grams, guideline: g) + " " + p.alcoholUnit.unitLabel(for: g)
    }

    var displayUnitDivisor: Double {
        guard let p = profile else { return 1.0 }
        return p.alcoholUnit.gramsPerUnit(for: p.guidelineChoice)
    }

    var displayUnitLabel: String {
        let unit = profile?.alcoholUnit ?? .standardDrinks
        return unit.unitLabel(for: guidelineChoice)
    }

    /// A number in the user's unit without its label (the comparison gauges add the label).
    func formattedNumber(_ grams: Double) -> String {
        (profile?.alcoholUnit ?? .standardDrinks).formattedValue(grams, guideline: guidelineChoice)
    }

    func formattedSpend(_ amount: Double) -> String {
        let code = profile?.currency ?? "EUR"
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = code
        return fmt.string(from: NSNumber(value: amount)) ?? "\(code) \(String(format: "%.2f", amount))"
    }

    func guidelineShortName(_ g: GuidelineChoice) -> String {
        switch g {
        case .who: return String(localized: "insights.guideline.who")
        case .uk:  return String(localized: "insights.guideline.nhs")
        case .de:  return String(localized: "insights.guideline.dhs")
        default:   return g.rawValue.uppercased()
        }
    }
}
