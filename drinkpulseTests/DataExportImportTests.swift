import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct DataExportImportTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // MARK: - Export

    @Test func encode_producesValidJSON() throws {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        let data = try DataExporter().encode([event])
        #expect(!data.isEmpty)
        // Must round-trip through JSONDecoder without throwing
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        _ = try decoder.decode(ExportBundle.self, from: data)
    }

    @Test func encode_emptyEvents_producesValidJSON() throws {
        let data = try DataExporter().encode([])
        #expect(!data.isEmpty)
    }

    @Test func fileName_containsDate() {
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01
        let name = DataExporter().fileName(for: date)
        #expect(name.hasPrefix("drinkpulse-backup-1970-01-01"))
        #expect(name.hasSuffix(".json"))
    }

    // MARK: - Round-trip

    @Test func roundTrip_preservesAllFields() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let original = ConsumptionEvent(
            timestamp:  Date(timeIntervalSince1970: 1_000_000),
            volumeMl:   330,
            abv:        0.055,
            name:       "Beer",
            category:   .beer,
            icon:       "🍺",
            customName: "Tyskie",
            notes:      "Friday night",
            price:      3.50
        )
        let data = try DataExporter().encode([original])
        let result = try DataImporter().importData(data, into: context)

        #expect(result.imported == 1)
        #expect(result.skipped == 0)
        #expect(result.failed == 0)

        let fetched = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(fetched.count == 1)
        let e = try #require(fetched.first)
        #expect(abs(e.timestamp.timeIntervalSince(original.timestamp)) < 1)
        #expect(e.volumeMl == 330)
        #expect(abs(e.abv - 0.055) < 0.0001)
        #expect(e.name == "Beer")
        #expect(e.category == .beer)
        #expect(e.customName == "Tyskie")
        #expect(e.notes == "Friday night")
        #expect(e.price == 3.50)
    }

    @Test func roundTrip_multipleEvents() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let events: [ConsumptionEvent] = [
            ConsumptionEvent(volumeMl: 500, abv: 0.05,  name: "Beer",    category: .beer,    icon: "🍺"),
            ConsumptionEvent(volumeMl: 175, abv: 0.135, name: "Wine",    category: .wine,    icon: "🍷"),
            ConsumptionEvent(volumeMl: 40,  abv: 0.40,  name: "Spirits", category: .spirits, icon: "🥃"),
        ]
        let data = try DataExporter().encode(events)
        let result = try DataImporter().importData(data, into: context)

        #expect(result.imported == 3)
        let fetched = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(fetched.count == 3)
    }

    // MARK: - Deduplication

    @Test func import_skipsExistingDuplicates() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let ts = Date(timeIntervalSince1970: 2_000_000)
        let event = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: 0.05,
                                     name: "Beer", category: .beer, icon: "🍺")
        context.insert(event)

        let data = try DataExporter().encode([event])

        let first  = try DataImporter().importData(data, into: context)
        #expect(first.skipped == 1)
        #expect(first.imported == 0)

        let fetched = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(fetched.count == 1)
    }

    @Test func importTwice_noDoubleInsert() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let events = [ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                        category: .beer, icon: "🍺")]
        let data = try DataExporter().encode(events)

        _ = try DataImporter().importData(data, into: context)
        let second = try DataImporter().importData(data, into: context)

        #expect(second.skipped == 1)
        let fetched = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(fetched.count == 1)
    }

    // MARK: - Error handling

    @Test func import_unknownCategory_countedAsFailed() throws {
        let container = try makeContainer()
        let context = container.mainContext

        // Craft JSON with an invalid category value
        let json = """
        {
          "version": 1,
          "exportedAt": "2026-01-01T00:00:00Z",
          "events": [{
            "timestamp": "2026-01-01T12:00:00Z",
            "volumeMl": 500, "abv": 0.05,
            "name": "Mystery", "category": "INVALID_CAT", "icon": "❓"
          }]
        }
        """.data(using: .utf8)!

        let result = try DataImporter().importData(json, into: context)
        #expect(result.failed == 1)
        #expect(result.imported == 0)
        #expect(!result.errors.isEmpty)
    }

    @Test func import_malformedJSON_throws() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let badData = "not json".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try DataImporter().importData(badData, into: context)
        }
    }
}
