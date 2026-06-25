import Testing
@testable import drinkpulse

/// Tests for the canonical alcohol calculation: volume_ml × ABV × 0.789
@MainActor
struct AlcoholCalculationTests {

    // Tolerance for floating-point comparisons — 0.789 is not exactly representable in IEEE 754.
    private let eps = 1e-9

    // MARK: - pureAlcoholGrams

    @Test func beerHalfLitre5Percent() {
        // 500 ml × 5% × 0.789 = 19.725 g
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        #expect(abs(event.pureAlcoholGrams - 19.725) < 1e-9)
    }

    @Test func wineSmallGlass() {
        // 125 ml × 12% × 0.789 = 11.835 g
        let event = ConsumptionEvent(volumeMl: 125, abv: 0.12, name: "Wine",
                                     category: .wine, icon: "🍷")
        #expect(abs(event.pureAlcoholGrams - 11.835) < 1e-9)
    }

    @Test func spiritsDouble() {
        // 50 ml × 40% × 0.789 = 15.78 g
        let event = ConsumptionEvent(volumeMl: 50, abv: 0.40, name: "Whisky",
                                     category: .spirits, icon: "🥃")
        #expect(abs(event.pureAlcoholGrams - 15.78) < 1e-9)
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

    // MARK: - alcoholGrams(density:) + quantity (plan-0025)

    @Test func alcoholGrams_unitsDensity_500ml5pct_is20g() {
        // Units (UK) display density 0.8 → 500 ml × 5 % = 20.0 g (clean unit math).
        let e = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer", category: .beer, icon: "🍺")
        #expect(abs(e.alcoholGrams(density: 0.8) - 20.0) < eps)
    }

    @Test func alcoholGrams_physicalDensity_matchesPureAlcoholGrams() {
        let e = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer", category: .beer, icon: "🍺")
        #expect(abs(e.alcoholGrams(density: 0.789) - 19.725) < eps)
        #expect(abs(e.pureAlcoholGrams - 19.725) < eps)
    }

    @Test func alcoholGrams_quantityMultiplies() {
        let e = ConsumptionEvent(volumeMl: 500, abv: 0.05, quantity: 10,
                                 name: "Beer", category: .beer, icon: "🍺")
        #expect(abs(e.alcoholGrams(density: 0.8) - 200.0) < eps)   // 10 × 20.0
        #expect(abs(e.pureAlcoholGrams - 197.25) < eps)            // 10 × 19.725
    }

    @Test func usStandardDrink_355ml5pct_at0789_is14g() {
        // A US standard drink is defined as 14 g; 0.789 lands it cleanly.
        let e = ConsumptionEvent(volumeMl: 355, abv: 0.05, name: "Beer", category: .beer, icon: "🍺")
        #expect(abs(e.alcoholGrams(density: 0.789) - 14.0) < 0.01)
    }
}
