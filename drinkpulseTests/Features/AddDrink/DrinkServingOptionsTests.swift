import Testing
@testable import drinkpulse

@MainActor
struct DrinkServingOptionsTests {

    // MARK: - volumeOptions

    @Test func test_volumeOptions_keepsForeignVolume_asCurrent() {
        // 300 ml ("0.3 L") is a metric-only beer serving.
        let options = DrinkServingOptions.volumeOptions(for: .beer, in: .imperial, keeping: 300)
        let kept = options.first { $0.volumeMl == 300 }
        #expect(kept?.name(in: .imperial) == "Current")
        #expect(options.map(\.volumeMl) == options.map(\.volumeMl).sorted())
        #expect(options.count == DrinkTypePreset.beer.volumes(for: .imperial).count + 1)
    }

    @Test func test_volumeOptions_knownVolume_addsNothing() {
        let options = DrinkServingOptions.volumeOptions(for: .beer, in: .metric, keeping: 500)
        #expect(options == DrinkTypePreset.beer.volumes(for: .metric))
    }

    @Test func test_volumeOptions_noKeptVolume_isUnitServings() {
        let options = DrinkServingOptions.volumeOptions(for: .wine, in: .usCustomary, keeping: nil)
        #expect(options == DrinkTypePreset.wine.volumes(for: .usCustomary))
    }

    @Test func test_volumeOptions_custom_usesCustomVolumes() {
        let options = DrinkServingOptions.volumeOptions(for: .custom, in: .metric, keeping: nil)
        #expect(options == DrinkTypePreset.customVolumes(for: .metric))
    }

    @Test func test_volumeOptions_unitWithoutServings_usesAll() {
        let preset = DrinkTypePreset(
            category: .beer, name: "Test", icon: "🍺",
            volumes: [.init(descriptor: "Only metric", volumeMl: 250, regions: [.metric])],
            abvValues: [0.05], defaultVolumeMl: 250, defaultABVIndex: 0
        )
        let options = DrinkServingOptions.volumeOptions(for: preset, in: .imperial, keeping: nil)
        #expect(options.map(\.volumeMl) == [250])
    }

    // MARK: - abvValues

    @Test func test_abvValues_followStep() {
        let fine = DrinkServingOptions.abvValues(for: .wine, stepPermille: 5)
        let coarse = DrinkServingOptions.abvValues(for: .wine, stepPermille: 10)
        #expect(fine.count == 200)
        #expect(fine.prefix(2) == [0.005, 0.010])
        #expect(coarse.count == 100)
        #expect(coarse.prefix(2) == [0.005, 0.015])
    }

    // MARK: - nearest

    @Test func test_nearest_snapsToGrid() {
        let grid = DrinkServingOptions.abvValues(for: .beer, stepPermille: 5)
        #expect(DrinkServingOptions.nearest(0.0537, in: grid) == 0.055)
    }

    @Test func test_nearest_emptyGrid_returnsInput() {
        #expect(DrinkServingOptions.nearest(0.0537, in: []) == 0.0537)
    }
}
