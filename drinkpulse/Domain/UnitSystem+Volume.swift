import Foundation

extension UnitSystem {
    /// Millilitres per US fluid ounce. Canonical conversion constant (plan-0030).
    nonisolated static let mlPerUSFluidOunce = 29.5735
    /// Millilitres per imperial fluid ounce. Canonical conversion constant (plan-0030).
    nonisolated static let mlPerImperialFluidOunce = 28.4131

    /// Millilitres in one fluid ounce of *this* unit system, or `nil` for `.metric`
    /// (metric has no fluid-ounce concept — it displays raw ml).
    nonisolated var mlPerFluidOunce: Double? {
        switch self {
        case .metric:      return nil
        case .usCustomary: return Self.mlPerUSFluidOunce
        case .imperial:    return Self.mlPerImperialFluidOunce
        }
    }

    /// Converts a canonical millilitre value to the unit system's fluid ounces.
    /// Returns the raw ml for `.metric`. Pure; no rounding applied here.
    nonisolated func fluidOunces(fromMl ml: Double) -> Double {
        guard let perOz = mlPerFluidOunce else { return ml }
        return ml / perOz
    }

    /// Short unit label for serving volumes (`"ml"` / `"fl oz"`).
    nonisolated var volumeUnitLabel: String {
        switch self {
        case .metric:
            return String(localized: "unit.ml")
        case .usCustomary, .imperial:
            return String(localized: "unit.flOz")
        }
    }

    /// Renders a canonical millilitre value in the active unit system.
    ///
    /// Rounding policy (plan-0030 domain rule): metric → whole ml; oz modes →
    /// one decimal place. The formatter is **pure** on `(ml, unitSystem)` — it
    /// holds no state and is agnostic to where the ml came from. Storage always
    /// keeps the canonical ml; a displayed/re-parsed oz value is never fed back
    /// into storage.
    nonisolated func formatVolume(_ ml: Double) -> String {
        switch self {
        case .metric:
            return String(
                format: String(localized: "volume.format.ml"),
                ml.rounded()
            )
        case .usCustomary, .imperial:
            return String(
                format: String(localized: "volume.format.flOz"),
                fluidOunces(fromMl: ml)
            )
        }
    }
}
