import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct DataImporterEdgeCaseTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // MARK: - Version handling

    @Test func import_v1Bundle_succeeds() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let json = """
        {
          "version": 1,
          "exportedAt": "2026-01-01T00:00:00Z",
          "events": [{
            "timestamp": "2026-01-01T12:00:00Z",
            "volumeMl": 500, "abv": 0.05,
            "name": "Beer", "category": "beer", "icon": "🍺"
          }]
        }
        """.data(using: .utf8)!

        let result = try DataImporter().importData(json, into: context)
        #expect(result.imported == 1)
    }

    @Test func import_unsupportedVersion_throwsError() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let json = """
        {
          "version": 999,
          "exportedAt": "2026-01-01T00:00:00Z",
          "events": []
        }
        """.data(using: .utf8)!

        #expect(throws: ImportError.self) {
            try DataImporter().importData(json, into: context)
        }
    }

    @Test func import_unsupportedVersion_errorDescriptionContainsVersion() throws {
        let error = ImportError.unsupportedVersion(42)
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("42"))
    }

    @Test func import_decodeFailure_errorDescriptionIsNonEmpty() throws {
        let underlying = NSError(domain: "test", code: 1)
        let error = ImportError.decodeFailure(underlying: underlying)
        #expect((error.errorDescription ?? "").isEmpty == false)
    }

    // MARK: - Deduplication

    @Test func import_skipsExistingDuplicates() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let ts = Date(timeIntervalSince1970: 2_000_000)
        let event = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: 0.05,
                                     name: "Beer", category: .beer, icon: "🍺")
        context.insert(event)

        let data = try BackupExport(events: [event], profile: nil).encoded()

        let first = try DataImporter().importData(data, into: context)
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
        let data = try BackupExport(events: events, profile: nil).encoded()

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

    @Test func import_malformedJSON_throwsDecodeFailure() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let badData = "not json".data(using: .utf8)!
        #expect(throws: ImportError.self) {
            try DataImporter().importData(badData, into: context)
        }
    }
}
