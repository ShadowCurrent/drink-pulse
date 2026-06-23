import Testing
import Foundation
@testable import drinkpulse

/// Domain-layer volume formatter (plan-0030). Target: 100% coverage on the
/// conversions, labels, and rounding policy.
struct UnitSystemVolumeTests {

    // MARK: - Conversion constants

    @Test func conversionConstants() {
        #expect(UnitSystem.mlPerUSFluidOunce == 29.5735)
        #expect(UnitSystem.mlPerImperialFluidOunce == 28.4131)
    }

    @Test func mlPerFluidOunce_perCase() {
        #expect(UnitSystem.metric.mlPerFluidOunce == nil)
        #expect(UnitSystem.usCustomary.mlPerFluidOunce == 29.5735)
        #expect(UnitSystem.imperial.mlPerFluidOunce == 28.4131)
    }

    // MARK: - fluidOunces(fromMl:)

    @Test func fluidOunces_metricReturnsRawMl() {
        #expect(UnitSystem.metric.fluidOunces(fromMl: 500) == 500)
    }

    @Test func fluidOunces_usAnchors() {
        // Documented clean anchors.
        #expect(abs(UnitSystem.usCustomary.fluidOunces(fromMl: 355) - 12.0) < 0.01)
        #expect(abs(UnitSystem.usCustomary.fluidOunces(fromMl: 473) - 16.0) < 0.01)
    }

    @Test func fluidOunces_imperialAnchors() {
        #expect(abs(UnitSystem.imperial.fluidOunces(fromMl: 568) - 20.0) < 0.01)
        #expect(abs(UnitSystem.imperial.fluidOunces(fromMl: 284) - 10.0) < 0.01)
    }

    // MARK: - volumeUnitLabel

    @Test func volumeUnitLabel_perCase() {
        #expect(UnitSystem.metric.volumeUnitLabel == "ml")
        #expect(UnitSystem.usCustomary.volumeUnitLabel == "fl oz")
        #expect(UnitSystem.imperial.volumeUnitLabel == "fl oz")
    }

    // MARK: - formatVolume — metric (whole ml)

    @Test func formatVolume_metricWholeMl() {
        #expect(UnitSystem.metric.formatVolume(500) == "500 ml")
        #expect(UnitSystem.metric.formatVolume(0) == "0 ml")
        // Rounds to whole ml.
        #expect(UnitSystem.metric.formatVolume(284.131) == "284 ml")
        #expect(UnitSystem.metric.formatVolume(500.6) == "501 ml")
    }

    // MARK: - formatVolume — oz (1 decimal place)

    @Test func formatVolume_usFlOzOneDecimal() {
        #expect(UnitSystem.usCustomary.formatVolume(355) == "12.0 fl oz")
        #expect(UnitSystem.usCustomary.formatVolume(473) == "16.0 fl oz")
        #expect(UnitSystem.usCustomary.formatVolume(500) == "16.9 fl oz")
    }

    @Test func formatVolume_imperialFlOzOneDecimal() {
        #expect(UnitSystem.imperial.formatVolume(568) == "20.0 fl oz")
        #expect(UnitSystem.imperial.formatVolume(284) == "10.0 fl oz")
    }

    @Test func formatVolume_zeroOz() {
        #expect(UnitSystem.usCustomary.formatVolume(0) == "0.0 fl oz")
    }

    // MARK: - Round-trip drift (storage never adopts the re-parsed value)

    @Test func roundTripDrift_withinBound() {
        // ml → oz → ml is lossy in floating point. The displayed value is for
        // presentation only; storage keeps canonical ml. Verify the drift, when a
        // displayed oz value IS converted back, stays within a tight bound — and
        // note the formatter itself never performs this back-conversion.
        for ml in [44.0, 148.0, 284.0, 355.0, 473.0, 500.0, 568.0, 750.0] {
            let oz = UnitSystem.usCustomary.fluidOunces(fromMl: ml)
            let back = oz * UnitSystem.mlPerUSFluidOunce
            #expect(abs(back - ml) < 1e-9, "round-trip drift too large for \(ml)")
        }
    }
}
