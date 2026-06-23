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

    // MARK: - Default volume / ABV indices

    @Test func allPresetsHaveDefaultVolumeInMasterList() {
        for preset in DrinkTypePreset.all {
            #expect(preset.volumes.contains(where: { $0.volumeMl == preset.defaultVolumeMl }),
                    "defaultVolumeMl \(preset.defaultVolumeMl) not in master list for \(preset.name)")
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

    // MARK: - Region filtering & coverage invariant (plan-0030)

    @Test func coverageInvariant_everyCategoryHasNativeEntryPerUnit() {
        // Required by plan-0030: for every (category × unitSystem) the filtered
        // list is non-empty AND the default selection is an entry tagged to that unit.
        for preset in DrinkTypePreset.all where preset.category != .custom {
            for unit in UnitSystem.allCases {
                let native = preset.volumes(for: unit)
                #expect(!native.isEmpty,
                        "\(preset.name) has no native serving for \(unit)")
                let defaultMl = preset.defaultVolumeMl(for: unit)
                #expect(native.contains(where: { $0.volumeMl == defaultMl }),
                        "\(preset.name) default \(defaultMl) for \(unit) is not a tagged entry")
            }
        }
    }

    @Test func volumesForUnit_returnsOnlyTaggedEntries() {
        let beer = DrinkTypePreset.beer
        for option in beer.volumes(for: .usCustomary) {
            #expect(option.regions.contains(.usCustomary))
        }
        // 355 ml (US can, 12 fl oz) is US-native; 568 ml (UK pint) is not.
        let usMls = beer.volumes(for: .usCustomary).map(\.volumeMl)
        #expect(usMls.contains(355))
        #expect(!usMls.contains(568))
        let impMls = beer.volumes(for: .imperial).map(\.volumeMl)
        #expect(impMls.contains(568))
        #expect(!impMls.contains(355))
    }

    @Test func nearestVolumeMl_reResolvesBySelectionAcrossUnitSwitch() {
        let beer = DrinkTypePreset.beer
        // A 500 ml metric selection switched to US re-resolves to the nearest
        // US-native serving (473 ml = 16 fl oz), not an array index.
        let resolved = beer.nearestVolumeMl(to: 500, in: .usCustomary)
        #expect(resolved == 473)
        // Switching back to metric re-resolves to nearest metric serving.
        let back = beer.nearestVolumeMl(to: 473, in: .metric)
        #expect(back == 500)
    }

    @Test func customVolumes_metricUses10mlSteps() {
        let metric = DrinkTypePreset.customVolumes(for: .metric)
        #expect(metric.first?.volumeMl == 10)
        #expect(metric.last?.volumeMl == 1000)
    }

    @Test func customVolumes_ozModesUseHalfOzSteps() {
        let us = DrinkTypePreset.customVolumes(for: .usCustomary)
        #expect(!us.isEmpty)
        // First row is 0.5 US fl oz.
        let firstOz = (us.first?.volumeMl ?? 0) / UnitSystem.mlPerUSFluidOunce
        #expect(abs(firstOz - 0.5) < 0.0001)
    }

    // MARK: - VolumeOption.label(for:) composition

    @Test func volumeOptionLabel_composesDescriptorAndUnit() {
        let can = DrinkTypePreset.VolumeOption(descriptor: "US can", volumeMl: 355,
                                               regions: [.usCustomary])
        #expect(can.label(for: .metric) == "US can · 355 ml")
        #expect(can.label(for: .usCustomary) == "US can · 12.0 fl oz")
    }

    @Test func nearestVolumeMl_fallsBackToDefaultWhenNoOptions() {
        // Synthetic preset whose options are tagged for no unit system at all:
        // nearestVolumeMl must fall back to the default.
        let empty = DrinkTypePreset(
            category: .custom, name: "X", icon: "x",
            volumes: [.init(descriptor: "", volumeMl: 999, regions: [])],
            abvValues: DrinkTypePreset.fullAbvRange,
            defaultVolumeMl: 250, defaultABVIndex: 9
        )
        #expect(empty.nearestVolumeMl(to: 500, in: .metric) == 250)
    }
}
