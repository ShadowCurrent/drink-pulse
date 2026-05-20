import Testing
import SwiftData
@testable import drinkpulse

@MainActor
struct DrinkTemplateTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: DrinkTemplate.self, ConsumptionEvent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func init_storesAllFields() throws {
        let c = try makeContainer()
        let t = DrinkTemplate(
            name: "Lager",
            category: .beer,
            defaultVolumeMl: 500,
            abv: 0.05,
            icon: "🍺",
            colorHex: "#FFD700"
        )
        c.mainContext.insert(t)
        try c.mainContext.save()

        let fetched = try c.mainContext.fetch(FetchDescriptor<DrinkTemplate>())
        #expect(fetched.count == 1)
        let stored = fetched[0]
        #expect(stored.name == "Lager")
        #expect(stored.category == .beer)
        #expect(stored.defaultVolumeMl == 500)
        #expect(stored.abv == 0.05)
        #expect(stored.icon == "🍺")
        #expect(stored.colorHex == "#FFD700")
    }

    @Test func init_defaultsFavoriteAndArchivedToFalse() throws {
        let c = try makeContainer()
        let t = DrinkTemplate(
            name: "Test",
            category: .wine,
            defaultVolumeMl: 175,
            abv: 0.135,
            icon: "🍷",
            colorHex: "#8B0000"
        )
        c.mainContext.insert(t)
        #expect(!t.isFavorite)
        #expect(!t.isArchived)
    }

    @Test func init_eventsStartEmpty() throws {
        let c = try makeContainer()
        let t = DrinkTemplate(
            name: "Test",
            category: .spirits,
            defaultVolumeMl: 50,
            abv: 0.40,
            icon: "🥃",
            colorHex: "#D4A017"
        )
        c.mainContext.insert(t)
        #expect(t.events.isEmpty)
    }
}
