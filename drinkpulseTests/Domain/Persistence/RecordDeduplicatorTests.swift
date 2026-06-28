import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// Covers the cross-device de-dup sweep + insert-time uniqueness (plan-0023).
@MainActor
struct RecordDeduplicatorTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // Retain the container in the caller — returning only `.mainContext`
        // would deallocate the container and tear down the store mid-test.
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func dedupe_collapsesSameUUID_keepingNewestModifiedDate() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let shared = UUID()

        let older = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        older.uuid = shared
        older.modifiedDate = Date(timeIntervalSince1970: 100)
        older.notes = "old"

        let newer = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        newer.uuid = shared
        newer.modifiedDate = Date(timeIntervalSince1970: 900)
        newer.notes = "new"

        context.insert(older)
        context.insert(newer)
        RecordDeduplicator.dedupe(ConsumptionEvent.self, in: context)
        try context.save()

        let all = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(all.count == 1)
        #expect(all.first?.notes == "new")
    }

    @Test func dedupe_leavesDistinctUUIDsUntouched() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let a = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        let b = ConsumptionEvent(volumeMl: 330, abv: 0.05, category: .beer, icon: "🍺")
        context.insert(a)
        context.insert(b)
        RecordDeduplicator.dedupe(ConsumptionEvent.self, in: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<ConsumptionEvent>()).count == 2)
    }

    @Test func dedupe_collapsesTemplates() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let shared = UUID()
        let t1 = DrinkTemplate(name: "A", category: .beer, defaultVolumeMl: 500, abv: 0.05, icon: "🍺", colorHex: "#000")
        t1.uuid = shared
        t1.modifiedDate = Date(timeIntervalSince1970: 1)
        let t2 = DrinkTemplate(name: "B", category: .beer, defaultVolumeMl: 500, abv: 0.05, icon: "🍺", colorHex: "#000")
        t2.uuid = shared
        t2.modifiedDate = Date(timeIntervalSince1970: 2)
        context.insert(t1)
        context.insert(t2)
        RecordDeduplicator.dedupe(DrinkTemplate.self, in: context)
        try context.save()

        let all = try context.fetch(FetchDescriptor<DrinkTemplate>())
        #expect(all.count == 1)
        #expect(all.first?.name == "B")
    }

    @Test func ensureUniqueIdentity_regeneratesOnCollision() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let shared = UUID()
        let existing = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        existing.uuid = shared
        context.insert(existing)

        let inserted = ConsumptionEvent(volumeMl: 330, abv: 0.05, category: .beer, icon: "🍺")
        inserted.uuid = shared          // forced collision
        context.insert(inserted)
        RecordDeduplicator.ensureUniqueIdentity(inserted, in: context)

        #expect(inserted.uuid != shared)
        #expect(existing.uuid == shared)
    }

    @Test func sweep_collapsesEventsTemplatesAndProfiles() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let u = UUID()
        let e1 = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        e1.uuid = u; e1.modifiedDate = Date(timeIntervalSince1970: 1)
        let e2 = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
        e2.uuid = u; e2.modifiedDate = Date(timeIntervalSince1970: 2)
        context.insert(e1); context.insert(e2)
        context.insert(UserProfile())
        context.insert(UserProfile())

        RecordDeduplicator.sweep(in: context)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<ConsumptionEvent>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<UserProfile>()).count == 1)
    }
}
