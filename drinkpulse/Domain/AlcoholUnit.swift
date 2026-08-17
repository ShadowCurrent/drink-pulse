import Foundation

enum AlcoholUnit: String, Codable, CaseIterable, Sendable {
    case grams
    case standardDrinks

    nonisolated init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AlcoholUnit(rawValue: raw) ?? .standardDrinks
    }
}

extension AlcoholUnit {
    nonisolated static let physicalDensityGramsPerMl = 0.789

    nonisolated func density(for guideline: GuidelineChoice) -> Double {
        switch self {
        case .grams:
            return Self.physicalDensityGramsPerMl
        case .standardDrinks:
            switch guideline {
            case .us, .ca: return Self.physicalDensityGramsPerMl
            case .who, .de, .uk, .au, .custom: return 0.8
            }
        }
    }

    nonisolated func gramsPerUnit(for guideline: GuidelineChoice) -> Double {
        switch self {
        case .grams:
            return 1.0
        case .standardDrinks:
            switch guideline {
            case .uk:                          return 8.0
            case .us:                          return 14.0
            case .ca:                          return 13.45
            case .who, .de, .au, .custom:      return 10.0
            }
        }
    }

    nonisolated func formattedValue(_ massGrams: Double, guideline: GuidelineChoice) -> String {
        String(format: "%.1f", massGrams / gramsPerUnit(for: guideline))
    }

    nonisolated func unitLabel(for guideline: GuidelineChoice) -> String {
        switch self {
        case .grams:
            return String(localized: "unit.g")
        case .standardDrinks:
            return guideline == .uk
                ? String(localized: "unit.units")
                : String(localized: "unit.standardDrinks")
        }
    }

    nonisolated var displayName: String {
        switch self {
        case .grams:          return String(localized: "settings.alcoholUnit.grams")
        case .standardDrinks: return String(localized: "settings.alcoholUnit.standardDrinks")
        }
    }
}
