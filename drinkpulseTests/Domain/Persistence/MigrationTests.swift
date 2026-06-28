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
                timestamp: eventStamp, volumeMl: 568, abv: 0.05, quantity: 3,
                enteredUnit: .imperial, name: "Beer", category: .beer, icon: "🍺",
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
        #expect(abs(e.timestamp.timeIntervalSince(eventStamp)) < 1)
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
}
