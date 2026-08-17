import Testing
@testable import drinkpulse

@MainActor
struct AlcoholCalculationTests {

    private let eps = 1e-9

    // MARK: - pureAlcoholGrams

    @Test func beerHalfLitre5Percent() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05,
                                     category: .beer, icon: "🍺")
        #expect(abs(event.pureAlcoholGrams - 19.725) < 1e-9)
    }

    @Test func wineSmallGlass() {
        let event = ConsumptionEvent(volumeMl: 125, abv: 0.12,
                                     category: .wine, icon: "🍷")
        #expect(abs(event.pureAlcoholGrams - 11.835) < 1e-9)
    }

    @Test func spiritsDouble() {
        let event = ConsumptionEvent(volumeMl: 50, abv: 0.40,
                                     category: .spirits, icon: "🥃")
        #expect(abs(event.pureAlcoholGrams - 15.78) < 1e-9)
    }

    @Test func zeroVolumeGivesZeroAlcohol() {
        let event = ConsumptionEvent(volumeMl: 0, abv: 0.05,
                                     category: .beer, icon: "🍺")
        #expect(event.pureAlcoholGrams == 0)
    }

    @Test func zeroAbvGivesZeroAlcohol() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0,
                                     category: .custom, icon: "🥤")
        #expect(event.pureAlcoholGrams == 0)
    }

    // MARK: - alcoholGrams(density:) + quantity (plan-0025)

    @Test func alcoholGrams_unitsDensity_500ml5pct_is20g() {
        let e = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        #expect(abs(e.alcoholGrams(density: 0.8) - 20.0) < eps)
    }

    @Test func alcoholGrams_physicalDensity_matchesPureAlcoholGrams() {
        let e = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        #expect(abs(e.alcoholGrams(density: 0.789) - 19.725) < eps)
        #expect(abs(e.pureAlcoholGrams - 19.725) < eps)
    }

    @Test func alcoholGrams_quantityMultiplies() {
        let e = ConsumptionEvent(volumeMl: 500, abv: 0.05, quantity: 10, category: .beer, icon: "🍺")
        #expect(abs(e.alcoholGrams(density: 0.8) - 200.0) < eps)
        #expect(abs(e.pureAlcoholGrams - 197.25) < eps)
    }

    @Test func usStandardDrink_355ml5pct_at0789_is14g() {
        let e = ConsumptionEvent(volumeMl: 355, abv: 0.05, category: .beer, icon: "🍺")
        #expect(abs(e.alcoholGrams(density: 0.789) - 14.0) < 0.01)
    }
}
