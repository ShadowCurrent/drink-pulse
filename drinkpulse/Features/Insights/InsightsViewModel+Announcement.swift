import Foundation

extension InsightsViewModel {

    /// Spoken after every period or offset change (plan 0046, D0046-14; HIG Charts: changes
    /// must not be conveyed by motion alone): "<friendly label>, <range>, <total spoken>".
    var periodAnnouncement: String {
        [friendlyLabel, rangeLabel, spokenTotal(periodTotalGrams)].joined(separator: ", ")
    }

    /// The total with the unit written out, picked the way `AlcoholUnit.unitLabel(for:)` picks
    /// its abbreviation.
    func spokenTotal(_ grams: Double) -> String {
        let unit = profile?.alcoholUnit ?? .standardDrinks
        let value = unit.formattedValue(grams, guideline: guidelineChoice)
        let format: String
        switch unit {
        case .grams:
            format = String(localized: "insights.announce.grams")
        case .standardDrinks:
            format = guidelineChoice == .uk
                ? String(localized: "insights.announce.units")
                : String(localized: "insights.announce.standardDrinks")
        }
        return String(format: format, value)
    }
}
