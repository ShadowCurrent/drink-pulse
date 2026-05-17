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

    @Test func beerAbvBounds() {
        #expect(DrinkTypePreset.beer.abvMin == 0.030)
        #expect(DrinkTypePreset.beer.abvMax == 0.120)
    }

    @Test func spiritsAbvBounds() {
        #expect(DrinkTypePreset.spirits.abvMin == 0.350)
        #expect(DrinkTypePreset.spirits.abvMax == 0.650)
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
