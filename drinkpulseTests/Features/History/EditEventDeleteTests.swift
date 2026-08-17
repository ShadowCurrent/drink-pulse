import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct EditEventDeleteTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: config
        )
    }

    @Test("Deleting an event removes it from the store")
    func delete_removesEvent() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        context.insert(event)
        #expect(try context.fetch(FetchDescriptor<ConsumptionEvent>()).count == 1)

        context.delete(event)

        #expect(try context.fetch(FetchDescriptor<ConsumptionEvent>()).isEmpty)
    }

    @Test("Deleting one event leaves other events intact")
    func delete_leavesSiblingsIntact() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let beer = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        let wine = ConsumptionEvent(volumeMl: 150, abv: 0.12, category: .wine, icon: "🍷")
        context.insert(beer)
        context.insert(wine)

        context.delete(beer)

        let remaining = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.category == .wine)
    }
}
