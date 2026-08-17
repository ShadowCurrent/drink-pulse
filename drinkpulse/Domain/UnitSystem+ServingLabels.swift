import Foundation

// MARK: - Serving-size labels (plan-0031 domain rule, hand-verified)

extension UnitSystem {
    nonisolated static let mlPerImperialPint = 568.0

    nonisolated func servingVolumeLabel(_ ml: Double) -> String {
        switch self {
        case .metric:
            return formatVolume(ml)
        case .usCustomary:
            return formatOunces(ml)
        case .imperial:
            return Self.pintLabel(forMl: ml) ?? formatOunces(ml)
        }
    }

    nonisolated func isRoundServing(_ ml: Double) -> Bool {
        switch self {
        case .metric:
            return true
        case .usCustomary:
            return isWholeOrHalfOunce(ml)
        case .imperial:
            return Self.pintLabel(forMl: ml) != nil || isWholeOrHalfOunce(ml)
        }
    }

    private nonisolated func isWholeOrHalfOunce(_ ml: Double) -> Bool {
        let oz10 = (fluidOunces(fromMl: ml) * 10).rounded()
        return oz10.truncatingRemainder(dividingBy: 5) == 0
    }

    nonisolated static func pintLabel(forMl ml: Double) -> String? {
        let pints = ml / mlPerImperialPint
        let nearestWhole = pints.rounded()
        if nearestWhole >= 1, abs(pints - nearestWhole) < 0.01 {
            let n = Int(nearestWhole)
            return n == 1
                ? String(localized: "volume.serving.pint.one")
                : String(format: String(localized: "volume.serving.pint.many"), Double(n))
        }
        let fractions: [(value: Double, label: String.LocalizationValue)] = [
            (1.0 / 3.0, "volume.serving.pint.third"),
            (1.0 / 2.0, "volume.serving.pint.half"),
            (2.0 / 3.0, "volume.serving.pint.twoThirds"),
        ]
        for f in fractions where abs(pints - f.value) < 0.01 {
            return String(localized: f.label)
        }
        return nil
    }

    private nonisolated func formatOunces(_ ml: Double) -> String {
        let oz = (fluidOunces(fromMl: ml) * 10).rounded() / 10
        if oz == oz.rounded() {
            return String(format: String(localized: "volume.serving.oz.whole"), oz)
        }
        return String(format: String(localized: "volume.serving.oz.decimal"), oz)
    }

    nonisolated func servingMlHint(_ ml: Double) -> String? {
        guard self != .metric, !isRoundServing(ml) else { return nil }
        return String(format: String(localized: "volume.serving.mlHint"), Double(Int(ml.rounded())))
    }
}
