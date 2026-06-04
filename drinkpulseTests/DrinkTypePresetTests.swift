import Testing
@testable import drinkpulse

@MainActor
struct DrinkTypePresetTests {

    // MARK: - preset(for:)

    @Test func presetLookupReturnCorrectCategory() {
        for category in DrinkCategory.allCases {
            let preset = DrinkTypePreset.preset(for: category)
            #expect(preset.category == category)
        }
    }

    // MARK: - abvRange

    @Test func abvRangeDefaultStep() {
        let values = DrinkTypePreset.abvRange(from: 30, through: 50)
        #expect(values == [0.030, 0.035, 0.040, 0.045, 0.050])
    }

    @Test func abvRangeFineStep() {
        let values = DrinkTypePreset.abvRange(from: 30, through: 32, step: 1)
        #expect(values == [0.030, 0.031, 0.032])
    }

    @Test func abvRangeLargeStep() {
        let values = DrinkTypePreset.abvRange(from: 350, through: 400, step: 10)
        #expect(values == [0.350, 0.360, 0.370, 0.380, 0.390, 0.400])
    }

    @Test func abvRangeNoFloatDrift() {
        // All values must be exact multiples of the step — no floating-point drift.
        let values = DrinkTypePreset.abvRange(from: 5, through: 500, step: 5)
        for value in values {
            let permille = Int((value * 1000).rounded())
            #expect(permille % 5 == 0, "Value \(value) is not a clean 0.5% step")
        }
    }

    // MARK: - abvMin / abvMax

    @Test func allPresetsShareFullAbvRange() {
        // All presets now use the universal 0.5 %–100 % range.
        for preset in DrinkTypePreset.all {
            #expect(preset.abvMin == 0.005, "\(preset.name) abvMin should be 0.5 %")
            #expect(preset.abvMax == 1.000, "\(preset.name) abvMax should be 100 %")
        }
    }

    @Test func beerDefaultAbvIsSelectableAt2Point5Percent() {
        // Regression: low-ABV values like 2.5 % must be in the full-range picker.
        let fineValues = DrinkTypePreset.abvRange(
            from: Int(DrinkTypePreset.beer.abvMin * 1000),
            through: Int(DrinkTypePreset.beer.abvMax * 1000),
            step: 5
        )
        #expect(fineValues.contains(0.025), "2.5 % beer must be selectable at step=5")
        #expect(fineValues.contains(0.005), "0.5 % beer must be selectable at step=5")
    }

    // MARK: - Volume/count recovery (EditEventView logic)

    @Test func recoversExactPintCount1() {
        let preset = DrinkTypePreset.beer
        let storedVolume = 568.0  // Pint × 1
        let (count, idx) = nearestCountAndIndex(for: storedVolume, preset: preset)
        #expect(count == 1)
        #expect(preset.volumes[idx].volumeMl == 568)
    }

    @Test func recoversDoublePintAsCount2() {
        let preset = DrinkTypePreset.beer
        let storedVolume = 1136.0  // Pint × 2
        let (count, idx) = nearestCountAndIndex(for: storedVolume, preset: preset)
        #expect(count == 2)
        #expect(preset.volumes[idx].volumeMl == 568)
    }

    @Test func recoversDoubleSpirits() {
        let preset = DrinkTypePreset.spirits
        let storedVolume = 100.0  // Double × 2
        let (count, idx) = nearestCountAndIndex(for: storedVolume, preset: preset)
        #expect(count == 2)
        #expect(preset.volumes[idx].volumeMl == 50)
    }

    @Test func allPresetsHaveValidDefaultIndices() {
        for preset in DrinkTypePreset.all {
            #expect(preset.defaultVolumeIndex < preset.volumes.count,
                    "defaultVolumeIndex out of bounds for \(preset.name)")
            #expect(preset.defaultABVIndex < preset.abvValues.count,
                    "defaultABVIndex out of bounds for \(preset.name)")
        }
    }

    @Test func allPresetsDefaultAbvIsRepresentableAtFineStep() {
        // defaultABV must be selectable in the picker at both step=5 and step=1 precision,
        // so the initial picker position is always correct regardless of user's setting.
        for preset in DrinkTypePreset.all {
            let defaultABV = preset.abvValues[preset.defaultABVIndex]
            let fineValues = DrinkTypePreset.abvRange(
                from: Int(preset.abvMin * 1000),
                through: Int(preset.abvMax * 1000),
                step: 1
            )
            #expect(fineValues.contains(defaultABV),
                    "defaultABV \(defaultABV) not representable at step=1 for \(preset.name)")
        }
    }

    @Test func beerDefaultAbvIs5Percent() {
        let beer = DrinkTypePreset.beer
        #expect(beer.abvValues[beer.defaultABVIndex] == 0.050)
    }

    // MARK: - Identifiable / Hashable

    @Test func preset_idEqualsCategory() {
        for preset in DrinkTypePreset.all {
            #expect(preset.id == preset.category)
        }
    }

    @Test func preset_equalityByCategory() {
        #expect(DrinkTypePreset.beer == DrinkTypePreset.beer)
        #expect(DrinkTypePreset.beer != DrinkTypePreset.wine)
    }

    @Test func preset_canBeInsertedIntoSet() {
        let set = Set(DrinkTypePreset.all)
        #expect(set.count == DrinkTypePreset.all.count)
    }

    // MARK: - Helpers

    /// Mirrors the brute-force search in EditEventView.init.
    private func nearestCountAndIndex(for volumeMl: Double,
                                       preset: DrinkTypePreset) -> (count: Int, index: Int) {
        var bestCount = 1
        var bestIndex = preset.defaultVolumeIndex
        var bestDiff  = Double.infinity
        for c in 1 ... 10 {
            for (idx, vol) in preset.volumes.enumerated() {
                let diff = abs(vol.volumeMl * Double(c) - volumeMl)
                if diff < bestDiff {
                    bestDiff  = diff
                    bestCount = c
                    bestIndex = idx
                }
            }
        }
        return (bestCount, bestIndex)
    }
}
