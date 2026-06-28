import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// Identity-based upsert + LWW on import (plan-0023).
@MainActor
struct DataImporterUpsertTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // Retain the container in the caller — returning only `.mainContext`
        // would deallocate the container and tear down the store mid-test.
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func encode(_ bundle: ExportBundle) throws -> Data {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return try enc.encode(bundle)
    }

    private func bundle(from events: [ConsumptionEvent]) -> ExportBundle {
        ExportBundle(events: events.map(ExportRecord.init))
    }

    @Test func reimportingSameBackup_isIdempotent() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        let data = try encode(bundle(from: [event]))

        let r1 = try DataImporter().importData(data, into: context)
        try context.save()
        let r2 = try DataImporter().importData(data, into: context)
        try context.save()

        #expect(r1.imported == 1)
        #expect(r2.imported == 0)
        #expect(r2.skipped == 1)
        #expect(try context.fetch(FetchDescriptor<ConsumptionEvent>()).count == 1)
    }

    @Test func conflictingUUID_newerModifiedDateWins() throws {
        let container = try makeContainer()
        let context = container.mainContext
        // Seed an existing event with a known uuid and an OLD modifiedDate.
        let existing = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        existing.modifiedDate = Date(timeIntervalSince1970: 1_000)
        existing.notes = "old"
        context.insert(existing)
        try context.save()

        // A backup carrying the SAME uuid, a NEWER modifiedDate and a changed field.
        let incoming = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        incoming.uuid = existing.uuid
        incoming.modifiedDate = Date(timeIntervalSince1970: 9_000)
        incoming.notes = "new"
        let data = try encode(bundle(from: [incoming]))

        let result = try DataImporter().importData(data, into: context)
        try context.save()

        let all = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(all.count == 1)
        #expect(all.first?.notes == "new")
        #expect(result.imported == 1)
    }

    @Test func conflictingUUID_olderModifiedDateIsSkipped() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let existing = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        existing.modifiedDate = Date(timeIntervalSince1970: 9_000)
        existing.notes = "current"
        context.insert(existing)
        try context.save()

        let stale = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        stale.uuid = existing.uuid
        stale.modifiedDate = Date(timeIntervalSince1970: 1_000)
        stale.notes = "stale"
        let data = try encode(bundle(from: [stale]))

        let result = try DataImporter().importData(data, into: context)
        try context.save()

        let all = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(all.count == 1)
        #expect(all.first?.notes == "current")
        #expect(result.skipped == 1)
    }

    @Test func legacyBackupWithoutUUID_fallsBackToHeuristic() throws {
        let container = try makeContainer()
        let context = container.mainContext
        // Build a v2-era JSON with NO uuid/modifiedDate keys (pre-identity backup).
        let stamp = ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: 5_000))
        let json = """
        {"version":2,"exportedAt":"\(stamp)","events":[
          {"timestamp":"\(stamp)","volumeMl":500,"abv":0.05,"quantity":1,"category":"beer","icon":"🍺"}
        ]}
        """
        let data = Data(json.utf8)

        let r1 = try DataImporter().importData(data, into: context)
        try context.save()
        // Re-import: the heuristic (timestamp/volume/abv/quantity) must skip it.
        let r2 = try DataImporter().importData(data, into: context)
        try context.save()

        #expect(r1.imported == 1)
        #expect(r2.skipped == 1)
        #expect(try context.fetch(FetchDescriptor<ConsumptionEvent>()).count == 1)
    }

    @Test func templatesRoundTripById() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let template = DrinkTemplate(name: "House Lager", category: .beer,
                                     defaultVolumeMl: 500, abv: 0.05, icon: "🍺", colorHex: "#C8A24B")
        let b = ExportBundle(events: [], templates: [TemplateRecord(from: template)])
        let data = try encode(b)

        let r1 = try DataImporter().importData(data, into: context)
        try context.save()
        let r2 = try DataImporter().importData(data, into: context)
        try context.save()

        _ = r1; _ = r2
        let all = try context.fetch(FetchDescriptor<DrinkTemplate>())
        #expect(all.count == 1)         // idempotent by uuid
        #expect(all.first?.name == "House Lager")
    }
}
