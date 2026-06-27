import Foundation

// MARK: - Serving-size labels (plan-0031 domain rule, hand-verified)

extension UnitSystem {
    /// Millilitres in one UK / imperial pint. Canonical constant (plan-0031).
    nonisolated static let mlPerImperialPint = 568.0

    /// Renders `ml` as a **serving-size** label in this unit system.
    ///
    /// Distinct from `formatVolume` (which always uses fl oz for non-metric):
    /// this is the serving-list / picker presentation that adopts **pint mode**
    /// for imperial. Policy (plan-0031, hand-verified — see `domain.md`):
    /// - metric      → whole ml (`"500 ml"`)
    /// - usCustomary → ounces, whole or one-decimal (`"16 oz"`, `"16.9 oz"`)
    /// - imperial    → pint fraction / whole pints when the volume is pint-native
    ///   (`"½ pint"`, `"1 pint"`, `"2 pints"`); otherwise ounces (`"12.5 oz"`).
    ///
    /// Pure on `(ml, unitSystem)`. Storage always keeps the canonical ml.
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

    /// True when `ml` renders as a "clean" serving in this unit — i.e. no inline
    /// ml hint is needed. Policy (plan-0031, hand-verified — see `domain.md`):
    /// the value lands on a **whole or half ounce**, OR (imperial only) on a
    /// **clean pint fraction**.
    /// - metric → always clean (ml IS the native number).
    /// - usCustomary → clean when the ounce value (rounded to 0.1) is a whole or
    ///   half ounce (473 ml = 16 oz, 44 ml = 1.5 oz). 500 ml = 16.9 oz → hinted.
    /// - imperial → clean when pint-native (⅓/½/⅔/whole pints) OR whole/half oz.
    ///   So cocktail/hot-drink oz pours (114 ml = 4 oz) stay clean, while a UK
    ///   real measure off the half-oz grid (125 ml = 4.4 oz) is hinted.
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

    /// True when `ml` rounds (to 0.1 oz) onto a whole or half ounce in this unit.
    private nonisolated func isWholeOrHalfOunce(_ ml: Double) -> Bool {
        let oz10 = (fluidOunces(fromMl: ml) * 10).rounded()
        return oz10.truncatingRemainder(dividingBy: 5) == 0
    }

    /// Pint label for an imperial serving, or nil when `ml` is not pint-native.
    /// Recognised: sub-pint fractions ⅓ / ½ / ⅔ and whole-pint multiples
    /// (1 pint, 2 pints, …). UK pint = 568 ml. Match tolerance is 0.01 pint
    /// (≈5.7 ml) so the rounded preset ml (189, 379, …) still resolve.
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

    /// Ounces for this unit (US or imperial fl oz), rounded to 0.1, with the
    /// trailing ".0" dropped: `"16 oz"`, `"4.4 oz"`. Not called for metric.
    private nonisolated func formatOunces(_ ml: Double) -> String {
        let oz = (fluidOunces(fromMl: ml) * 10).rounded() / 10
        if oz == oz.rounded() {
            return String(format: String(localized: "volume.serving.oz.whole"), oz)
        }
        return String(format: String(localized: "volume.serving.oz.decimal"), oz)
    }

    /// Appends the inline ml hint to a composed serving label when the volume is
    /// not a clean serving in this (non-metric) unit, per plan-0031. The hint
    /// uses `Int(ml.rounded())` — never `Int(ml)` — so custom oz-wheel ml
    /// (14.78) and non-integer historical ml (444.5) round, not truncate.
    nonisolated func servingMlHint(_ ml: Double) -> String? {
        guard self != .metric, !isRoundServing(ml) else { return nil }
        return String(format: String(localized: "volume.serving.mlHint"), Double(Int(ml.rounded())))
    }
}
