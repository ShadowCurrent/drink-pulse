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
        let values = DrinkTypePreset.abvRange(from: 5, through: 500, step: 5)
        for value in values {
            let permille = Int((value * 1000).rounded())
            #expect(permille % 5 == 0, "Value \(value) is not a clean 0.5% step")
        }
    }

    // MARK: - abvMin / abvMax

    @Test func allPresetsShareFullAbvRange() {
        for preset in DrinkTypePreset.all {
            #expect(preset.abvMin == 0.005, "\(preset.name) abvMin should be 0.5 %")
            #expect(preset.abvMax == 1.000, "\(preset.name) abvMax should be 100 %")
        }
    }

    @Test func beerDefaultAbvIsSelectableAt2Point5Percent() {
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
        let usMls = beer.volumes(for: .usCustomary).map(\.volumeMl)
        #expect(usMls.contains(355))
        #expect(usMls.contains(568))
        let impMls = beer.volumes(for: .imperial).map(\.volumeMl)
        #expect(impMls.contains(568))
        #expect(impMls.contains(355))
    }

    @Test func defaultVolumeMl_imperialBeerDefaultsToOnePint() {
        let beer = DrinkTypePreset.beer
        #expect(beer.defaultVolumeMl(for: .imperial) == 568)
        #expect(beer.defaultVolumeMl(for: .metric) == 500)
        #expect(beer.defaultVolumeMl(for: .usCustomary) == 500)
    }

    @Test func defaultVolumeMl_regionDefaultSnapsToNearestWhenNotNative() {
        let preset = DrinkTypePreset(
            category: .beer, name: "T", icon: "🍺",
            volumes: [
                .init(descriptor: "A", volumeMl: 300, regions: [.imperial]),
                .init(descriptor: "B", volumeMl: 500, regions: [.imperial]),
            ],
            abvValues: [0.05], defaultVolumeMl: 500, defaultABVIndex: 0,
            regionDefaults: [.imperial: 480]
        )
        #expect(preset.defaultVolumeMl(for: .imperial) == 500)
    }

    @Test func nearestVolumeMl_reResolvesBySelectionAcrossUnitSwitch() {
        let beer = DrinkTypePreset.beer
        let resolved = beer.nearestVolumeMl(to: 440, in: .usCustomary)
        #expect(resolved == 473)
        let back = beer.nearestVolumeMl(to: 473, in: .metric)
        #expect(back == 500)
    }

    // MARK: - Duplicate-ml invariant (plan-0031)

    @Test func volumesForUnit_haveNoDuplicateMl_perCategoryAndUnit() {
        for preset in DrinkTypePreset.all where preset.category != .custom {
            for unit in UnitSystem.allCases {
                let mls = preset.volumes(for: unit).map(\.volumeMl)
                #expect(Set(mls).count == mls.count,
                        "\(preset.name) has duplicate ml in the \(unit) list: \(mls)")
            }
        }
    }

    @Test func customVolumes_metricUses10mlSteps() {
        let metric = DrinkTypePreset.customVolumes(for: .metric)
        #expect(metric.first?.volumeMl == 10)
        #expect(metric.last?.volumeMl == 1000)
    }

    @Test func customVolumes_ozModesUseHalfOzSteps() {
        let us = DrinkTypePreset.customVolumes(for: .usCustomary)
        #expect(!us.isEmpty)
        let firstOz = (us.first?.volumeMl ?? 0) / UnitSystem.mlPerUSFluidOunce
        #expect(abs(firstOz - 0.5) < 0.0001)
    }

    // MARK: - VolumeOption.name(in:) / label(in:) composition (plan-0031)

    @Test func volumeOptionName_perRegionOverride() {
        let pint = DrinkTypePreset.VolumeOption(descriptor: "Pint", volumeMl: 568,
                                                regions: [.metric, .usCustomary, .imperial],
                                                regionNames: [.usCustomary: "Stovepipe"])
        #expect(pint.name(in: .metric) == "Pint")
        #expect(pint.name(in: .imperial) == "Pint")
        #expect(pint.name(in: .usCustomary) == "Stovepipe")
    }

    @Test func volumeOptionLabel_roundServing_hasNoMlHint() {
        let can = DrinkTypePreset.VolumeOption(descriptor: "Can", volumeMl: 355,
                                               regions: [.usCustomary])
        #expect(can.label(in: .metric) == "Can · 355 ml")
        #expect(can.label(in: .usCustomary) == "Can · 12 oz")
    }

    @Test func volumeOptionLabel_nonRoundServing_appendsMlHint() {
        let small = DrinkTypePreset.VolumeOption(descriptor: "Small", volumeMl: 125,
                                                 regions: [.imperial])
        #expect(small.label(in: .imperial) == "Small · 4.4 oz · 125 ml")
        #expect(small.label(in: .metric) == "Small · 125 ml")
    }

    @Test func volumeOptionLabel_imperialPint_rendersFraction() {
        let pint = DrinkTypePreset.VolumeOption(descriptor: "Pint", volumeMl: 568,
                                                regions: [.imperial, .usCustomary],
                                                regionNames: [.usCustomary: "Stovepipe"])
        #expect(pint.label(in: .imperial) == "Pint · 1 pint")
        #expect(pint.label(in: .usCustomary) == "Stovepipe · 19.2 oz · 568 ml")
    }

    @Test func nearestVolumeMl_fallsBackToDefaultWhenNoOptions() {
        let empty = DrinkTypePreset(
            category: .custom, name: "X", icon: "x",
            volumes: [.init(descriptor: "", volumeMl: 999, regions: [])],
            abvValues: DrinkTypePreset.fullAbvRange,
            defaultVolumeMl: 250, defaultABVIndex: 9
        )
        #expect(empty.nearestVolumeMl(to: 500, in: .metric) == 250)
    }
}
