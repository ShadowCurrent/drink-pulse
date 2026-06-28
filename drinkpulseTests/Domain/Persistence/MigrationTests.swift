import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// Migration harness for the plan-0035 versioned-schema foundation.
///
/// Proves that an on-disk store seeded under the current schema reopens cleanly
/// through the explicit `MigrationPlan`-governed `StoreBootstrap.makeContainer`
/// with its data intact. Built so plan-0023 can drop in a V1 → V2 case by
/// re-seeding here and asserting against the migrated shape.
@MainActor
struct MigrationTests {

    private func makeTempStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
    }

    private func makeSchema() -> Schema {
        Schema([DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self])
    }

    @Test func store_reopensUnderMigrationPlan_withDataIntact() throws {
        let url = makeTempStoreURL()
        let schema = makeSchema()
        let config = ModelConfiguration(schema: schema, url: url)
        let fm = FileManager.default
        let dob = Date(timeIntervalSince1970: 500_000)
        let eventStamp = Date(timeIntervalSince1970: 1_234_567)

        defer {
            for suffix in ["", "-wal", "-shm"] {
                let file = url.deletingPathExtension()
                    .appendingPathExtension(url.pathExtension + suffix)
                try? fm.removeItem(at: file)
            }
        }

        // --- Seed under a MigrationPlan-governed container, then release it so
        //     the file is flushed to disk before we reopen. ---
        do {
            let container = try StoreBootstrap.makeContainer(schema: schema, configuration: config)
            let context = container.mainContext

            let profile = UserProfile(
                bodyWeightKg: 82.5,
                biologicalSex: .female,
                dateOfBirth: dob,
                guidelineChoice: .uk,
                weeklyGoalGrams: 112.0,
                unitSystem: .imperial,
                currency: "GBP",
                abvPrecisionPermille: 1,
                alcoholUnit: .standardDrinks
            )
            let template = DrinkTemplate(
                name: "Lager", category: .beer, defaultVolumeMl: 500, abv: 0.05,
                icon: "mug.fill", colorHex: "#F5A623", isFavorite: true
            )
            let event = ConsumptionEvent(
                consumptionDate: eventStamp, volumeMl: 568, abv: 0.05, quantity: 3,
                enteredUnit: .imperial, category: .beer, icon: "🍺",
                customName: "Pint", notes: "Pub", price: 5.40, priceCurrency: "GBP"
            )
            context.insert(profile)
            context.insert(template)
            context.insert(event)
            try context.save()
            // `container` is the only reference; it is released at the end of this
            // scope, flushing the store so the reopen below reads from disk.
        }

        // --- Reopen the SAME url through MigrationPlan-governed makeContainer. ---
        // Reasoning: had the explicit MigrationPlan failed to open the store,
        // StoreBootstrap would fall through to its non-destructive RecoveredStores/
        // move-aside and hand back a FRESH EMPTY container. The non-empty,
        // field-correct fetch below therefore proves the store opened *by the
        // migration plan*, not by the recovery fallback.
        //
        // (We deliberately do NOT assert on the count of RecoveredStores/ folders:
        // that directory lives in shared Application Support and is mutated by the
        // parallel StoreBootstrapTests, so a before/after diff would be flaky. The
        // data-intact assertion is the reliable proof of a clean open.)
        let reopened = try StoreBootstrap.makeContainer(schema: schema, configuration: config)
        let context = reopened.mainContext

        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        let templates = try context.fetch(FetchDescriptor<DrinkTemplate>())
        let events = try context.fetch(FetchDescriptor<ConsumptionEvent>())

        #expect(profiles.count == 1)
        #expect(templates.count == 1)
        #expect(events.count == 1)

        let p = try #require(profiles.first)
        #expect(p.bodyWeightKg == 82.5)
        #expect(p.biologicalSex == .female)
        #expect(p.dateOfBirth == dob)
        #expect(p.guidelineChoice == .uk)
        #expect(p.weeklyGoalGrams == 112.0)
        #expect(p.unitSystem == .imperial)
        #expect(p.currency == "GBP")
        #expect(p.abvPrecisionPermille == 1)
        #expect(p.alcoholUnit == .standardDrinks)

        let e = try #require(events.first)
        #expect(abs(e.consumptionDate.timeIntervalSince(eventStamp)) < 1)
        #expect(e.volumeMl == 568)
        #expect(e.quantity == 3)
        #expect(e.enteredUnit == .imperial)
        #expect(e.customName == "Pint")
        #expect(e.notes == "Pub")
        #expect(e.price == 5.40)
        #expect(e.priceCurrency == "GBP")

        let t = try #require(templates.first)
        #expect(t.name == "Lager")
        #expect(t.isFavorite == true)
    }

    /// V1 → V2 (plan-0023): a store seeded under the frozen `SchemaV1` snapshot
    /// (with `name`, no `uuid`/`modifiedDate`) reopens through `MigrationPlan`'s
    /// custom stage with data intact, distinct backfilled `uuid`s, and a populated
    /// `modifiedDate`.
    @Test func v1Store_migratesToV2_withIdentityBackfilled() throws {
        let url = makeTempStoreURL()
        let fm = FileManager.default
        let eventStamp = Date(timeIntervalSince1970: 1_234_567)
        defer {
            for suffix in ["", "-wal", "-shm"] {
                let file = url.deletingPathExtension()
                    .appendingPathExtension(url.pathExtension + suffix)
                try? fm.removeItem(at: file)
            }
        }

        // --- Seed an on-disk store under the explicit V1 schema (no migration). ---
        do {
            let v1Schema = Schema(versionedSchema: SchemaV1.self)
            let config = ModelConfiguration(schema: v1Schema, url: url)
            let container = try ModelContainer(for: v1Schema, configurations: [config])
            let context = container.mainContext
            let profile = SchemaV1.UserProfile(bodyWeightKg: 77, biologicalSex: .male)
            let e1 = SchemaV1.ConsumptionEvent(timestamp: eventStamp, volumeMl: 500, abv: 0.05,
                                               name: "Beer", category: .beer, icon: "🍺")
            let e2 = SchemaV1.ConsumptionEvent(timestamp: eventStamp.addingTimeInterval(60),
                                               volumeMl: 330, abv: 0.05, name: "Beer",
                                               category: .beer, icon: "🍺")
            context.insert(profile)
            context.insert(e1)
            context.insert(e2)
            try context.save()
        }

        // --- Reopen through MigrationPlan (V1 → V2 custom stage) on the V2 schema. ---
        let v2Schema = makeSchema()
        let v2Config = ModelConfiguration(schema: v2Schema, url: url)
        let reopened = try StoreBootstrap.makeContainer(schema: v2Schema, configuration: v2Config)
        let context = reopened.mainContext

        let events = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())

        // Data intact (a recovery fallback would have yielded an empty store).
        #expect(events.count == 2)
        #expect(profiles.count == 1)

        // Distinct, non-sentinel uuids were backfilled per row.
        let uuids = Set(events.map(\.uuid))
        #expect(uuids.count == 2)

        // modifiedDate + creationDate seeded to each event's own consumptionDate;
        // profile got `.now`.
        let sentinel = Date(timeIntervalSince1970: 0)
        for event in events {
            #expect(event.modifiedDate != sentinel)
            #expect(abs(event.modifiedDate.timeIntervalSince(event.consumptionDate)) < 1)
            #expect(abs(event.creationDate.timeIntervalSince(event.consumptionDate)) < 1)
        }
        #expect(profiles.first?.modifiedDate != sentinel)
    }
}
