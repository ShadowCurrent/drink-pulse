import Testing
@testable import drinkpulse

struct ConsumptionEventTests {

    // MARK: - displayName: customName override

    @Test func displayName_returnsCustomName_whenSet() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺", customName: "Tyskie")
        #expect(event.displayName == "Tyskie")
    }

    @Test func displayName_trimsLeadingTrailingWhitespace() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺", customName: "  Tyskie  ")
        #expect(event.displayName == "Tyskie")
    }

    @Test func displayName_preservesInternalWhitespace() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺", customName: "Tyskie Full")
        #expect(event.displayName == "Tyskie Full")
    }

    // MARK: - displayName: derived from category + volume when customName absent

    @Test func displayName_derivedFromVolume_whenCustomNameIsNil() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        #expect(event.displayName == "Can")
    }

    @Test func displayName_derivedFromVolume_whenCustomNameIsEmpty() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺", customName: "")
        #expect(event.displayName == "Can")
    }

    @Test func displayName_derivedFromVolume_whenCustomNameIsWhitespaceOnly() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺", customName: "   ")
        #expect(event.displayName == "Can")
    }

    @Test func displayName_exactVolumeMatch_beer473() {
        let event = ConsumptionEvent(volumeMl: 473, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        #expect(event.displayName == "US pint")
    }

    @Test func displayName_exactVolumeMatch_beerPintUK() {
        let event = ConsumptionEvent(volumeMl: 568, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        #expect(event.displayName == "Pint UK")
    }

    @Test func displayName_nearestVolumeMatch_usedWhenNoExact() {
        // 490 ml — closest beer option is Bottle (500 ml)
        let event = ConsumptionEvent(volumeMl: 490, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        #expect(event.displayName == "Bottle")
    }

    @Test func displayName_wineStandardGlass() {
        let event = ConsumptionEvent(volumeMl: 150, abv: 0.13, name: "Wine",
                                     category: .wine, icon: "🍷")
        #expect(event.displayName == "Standard")
    }

    @Test func displayName_fallsBackToPresetName_forCustomCategory() {
        // Custom preset labels ("100 ml") have no "Name · Volume" separator
        let event = ConsumptionEvent(volumeMl: 250, abv: 0.05, name: "Other",
                                     category: .custom, icon: "🥤")
        #expect(event.displayName == "Custom")
    }

    // MARK: - displayName: quantity ×N (plan-0025)

    @Test func displayName_appendsQuantity_whenMoreThanOne() {
        // Single-portion 500 ml resolves to "Bottle"; quantity 10 → "Bottle ×10".
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, quantity: 10,
                                     name: "Beer", category: .beer, icon: "🍺")
        #expect(event.displayName == "Bottle ×10")
    }

    @Test func displayName_noQuantitySuffix_whenOne() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05,
                                     name: "Beer", category: .beer, icon: "🍺")
        #expect(event.displayName == "Bottle")
    }

    @Test func displayName_customNameWithQuantity() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, quantity: 3,
                                     name: "Beer", category: .beer, icon: "🍺", customName: "Tyskie")
        #expect(event.displayName == "Tyskie ×3")
    }
}
