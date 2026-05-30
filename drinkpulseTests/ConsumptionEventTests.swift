import Testing
@testable import drinkpulse

struct ConsumptionEventTests {

    // MARK: - displayName

    @Test func displayName_returnsName_whenCustomNameIsNil() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        #expect(event.displayName == "Beer")
    }

    @Test func displayName_returnsCustomName_whenSet() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "����", customName: "Tyskie")
        #expect(event.displayName == "Tyskie")
    }

    @Test func displayName_returnsName_whenCustomNameIsEmpty() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺", customName: "")
        #expect(event.displayName == "Beer")
    }

    @Test func displayName_returnsName_whenCustomNameIsWhitespaceOnly() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺", customName: "   ")
        #expect(event.displayName == "Beer")
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
}
