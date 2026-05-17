import Testing
@testable import drinkpulse

/// Tests for the canonical alcohol calculation: volume_ml × ABV × 0.8
@MainActor
struct AlcoholCalculationTests {

    // MARK: - pureAlcoholGrams

    @Test func beerHalfLitre5Percent() {
        // Reference value cited in BZgA materials: 500 ml × 5% × 0.8 = 20 g
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        #expect(event.pureAlcoholGrams == 20.0)
    }

    @Test func wineSmallGlass() {
        // 125 ml × 12% × 0.8 = 12 g
        let event = ConsumptionEvent(volumeMl: 125, abv: 0.12, name: "Wine",
                                     category: .wine, icon: "🍷")
        #expect(event.pureAlcoholGrams == 12.0)
    }

    @Test func spiritsDouble() {
        // 50 ml × 40% × 0.8 = 16 g
        let event = ConsumptionEvent(volumeMl: 50, abv: 0.40, name: "Whisky",
                                     category: .spirits, icon: "🥃")
        #expect(event.pureAlcoholGrams == 16.0)
    }

    @Test func zeroVolumeGivesZeroAlcohol() {
        let event = ConsumptionEvent(volumeMl: 0, abv: 0.05, name: "Empty",
                                     category: .beer, icon: "🍺")
        #expect(event.pureAlcoholGrams == 0)
    }

    @Test func zeroAbvGivesZeroAlcohol() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0, name: "Soft",
                                     category: .custom, icon: "🥤")
        #expect(event.pureAlcoholGrams == 0)
    }
}
