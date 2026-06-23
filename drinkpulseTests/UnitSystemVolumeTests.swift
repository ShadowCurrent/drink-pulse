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

    // MARK: - servingVolumeLabel — US ounces (plan-0031, hand-verified)

    @Test func servingVolumeLabel_usWholeAndDecimalOunces() {
        #expect(UnitSystem.usCustomary.servingVolumeLabel(355) == "12 oz")
        #expect(UnitSystem.usCustomary.servingVolumeLabel(473) == "16 oz")
        #expect(UnitSystem.usCustomary.servingVolumeLabel(44) == "1.5 oz")
        #expect(UnitSystem.usCustomary.servingVolumeLabel(30) == "1 oz")
        #expect(UnitSystem.usCustomary.servingVolumeLabel(500) == "16.9 oz")
        #expect(UnitSystem.usCustomary.servingVolumeLabel(568) == "19.2 oz")
    }

    @Test func servingVolumeLabel_metricWholeMl() {
        #expect(UnitSystem.metric.servingVolumeLabel(568) == "568 ml")
        #expect(UnitSystem.metric.servingVolumeLabel(444.5) == "445 ml")
    }

    // MARK: - servingVolumeLabel — imperial pints & ounces

    @Test func servingVolumeLabel_imperialPintFractions() {
        #expect(UnitSystem.imperial.servingVolumeLabel(189) == "⅓ pint")
        #expect(UnitSystem.imperial.servingVolumeLabel(284) == "½ pint")
        #expect(UnitSystem.imperial.servingVolumeLabel(379) == "⅔ pint")
        #expect(UnitSystem.imperial.servingVolumeLabel(568) == "1 pint")
        #expect(UnitSystem.imperial.servingVolumeLabel(1136) == "2 pints")
    }

    @Test func servingVolumeLabel_imperialNonPintFallsBackToOunces() {
        #expect(UnitSystem.imperial.servingVolumeLabel(125) == "4.4 oz")
        #expect(UnitSystem.imperial.servingVolumeLabel(355) == "12.5 oz")
        #expect(UnitSystem.imperial.servingVolumeLabel(114) == "4 oz")
    }

    // MARK: - isRoundServing

    @Test func isRoundServing_metricAlwaysTrue() {
        #expect(UnitSystem.metric.isRoundServing(125))
        #expect(UnitSystem.metric.isRoundServing(444.5))
    }

    @Test func isRoundServing_usWholeOrHalfOunce() {
        #expect(UnitSystem.usCustomary.isRoundServing(355))   // 12.0 oz
        #expect(UnitSystem.usCustomary.isRoundServing(44))    // 1.5 oz
        #expect(!UnitSystem.usCustomary.isRoundServing(500))  // 16.9 oz
        #expect(!UnitSystem.usCustomary.isRoundServing(568))  // 19.2 oz
    }

    @Test func isRoundServing_imperialPintOrWholeHalfOunce() {
        #expect(UnitSystem.imperial.isRoundServing(568))   // 1 pint
        #expect(UnitSystem.imperial.isRoundServing(189))   // ⅓ pint
        #expect(UnitSystem.imperial.isRoundServing(114))   // 4 oz (whole)
        #expect(UnitSystem.imperial.isRoundServing(355))   // 12.5 oz (half)
        #expect(!UnitSystem.imperial.isRoundServing(125))  // 4.4 oz
        #expect(!UnitSystem.imperial.isRoundServing(175))  // 6.2 oz
    }

    // MARK: - pintLabel

    @Test func pintLabel_recognisesFractionsAndWholes() {
        #expect(UnitSystem.pintLabel(forMl: 189) == "⅓ pint")
        #expect(UnitSystem.pintLabel(forMl: 284) == "½ pint")
        #expect(UnitSystem.pintLabel(forMl: 379) == "⅔ pint")
        #expect(UnitSystem.pintLabel(forMl: 568) == "1 pint")
        #expect(UnitSystem.pintLabel(forMl: 1136) == "2 pints")
    }

    @Test func pintLabel_nilForNonPint() {
        #expect(UnitSystem.pintLabel(forMl: 125) == nil)
        #expect(UnitSystem.pintLabel(forMl: 355) == nil)
        #expect(UnitSystem.pintLabel(forMl: 500) == nil)
    }

    // MARK: - servingMlHint (inline hint + rounding, never truncation)

    @Test func servingMlHint_metricNever() {
        #expect(UnitSystem.metric.servingMlHint(125) == nil)
    }

    @Test func servingMlHint_skippedForRoundServings() {
        #expect(UnitSystem.usCustomary.servingMlHint(355) == nil)   // 12 oz round
        #expect(UnitSystem.imperial.servingMlHint(568) == nil)      // 1 pint round
    }

    @Test func servingMlHint_appendedForNonRound() {
        #expect(UnitSystem.usCustomary.servingMlHint(500) == "500 ml")
        #expect(UnitSystem.imperial.servingMlHint(125) == "125 ml")
    }

    @Test func servingMlHint_usesRoundingNotTruncation() {
        // Int(444.5) would truncate to 444; the hint must round to 445.
        #expect(UnitSystem.imperial.servingMlHint(444.5) == "445 ml")
        // Int(24.78) would truncate to 24; the hint must round to 25.
        #expect(UnitSystem.usCustomary.servingMlHint(24.78) == "25 ml")
    }
}
