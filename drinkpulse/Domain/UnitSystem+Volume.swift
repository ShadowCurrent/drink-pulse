import Foundation

extension UnitSystem {
    nonisolated static let mlPerUSFluidOunce = 29.5735
    nonisolated static let mlPerImperialFluidOunce = 28.4131

    nonisolated var mlPerFluidOunce: Double? {
        switch self {
        case .metric:      return nil
        case .usCustomary: return Self.mlPerUSFluidOunce
        case .imperial:    return Self.mlPerImperialFluidOunce
        }
    }

    nonisolated func fluidOunces(fromMl ml: Double) -> Double {
        guard let perOz = mlPerFluidOunce else { return ml }
        return ml / perOz
    }

    nonisolated var volumeUnitLabel: String {
        switch self {
        case .metric:
            return String(localized: "unit.ml")
        case .usCustomary, .imperial:
            return String(localized: "unit.flOz")
        }
    }

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
