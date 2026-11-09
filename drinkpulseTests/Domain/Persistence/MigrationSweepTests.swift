import Testing
import Foundation
import SwiftData
@testable import drinkpulse

// The launch sweep (RecordDeduplicator.sweep) groups strictly by uuid. These
// tests prove it merges and drops nothing legitimate in a freshly migrated
// legacy store, including events whose field values are all identical.
@MainActor
struct MigrationSweepTests {

    private struct SweepResult {
        let migrated: StoreSnapshot
        let afterSweep: StoreSnapshot
        let afterSecondSweep: StoreSnapshot
    }

    private func migrateAndSweep(_ url: URL) throws -> SweepResult {
        let schema = MigrationFixtures.liveSchema()
        let config = ModelConfiguration(schema: schema, url: url)
        let (container, didRecover) = try StoreBootstrap.makeContainerReportingRecovery(
            schema: schema, configuration: config
        )
        #expect(!didRecover)
        let context = container.mainContext
        let migrated = try StoreSnapshot.take(from: context)

        RecordDeduplicator.sweep(in: context)
        try context.save()
        let afterSweep = try StoreSnapshot.take(from: context)

        RecordDeduplicator.sweep(in: context)
        try context.save()
        let afterSecondSweep = try StoreSnapshot.take(from: context)

        return SweepResult(migrated: migrated, afterSweep: afterSweep, afterSecondSweep: afterSecondSweep)
    }

    private func expectNothingMergedOrDropped(_ result: SweepResult, events: Int) {
        #expect(result.migrated.eventCount == events)
        #expect(result.migrated.templateCount == 1)
        #expect(result.migrated.profileCount == 1)
        #expect(result.afterSweep == result.migrated)
        #expect(result.afterSecondSweep == result.afterSweep)
    }

    @Test func sweep_overMigratedV1Store_changesNothing() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        _ = try MigrationFixtures.seedV1Store(at: url)

        expectNothingMergedOrDropped(try migrateAndSweep(url), events: 2)
    }

    @Test func sweep_overMigratedV2Store_changesNothing_andKeepsSeededUUIDs() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        let seeded = try MigrationFixtures.seedV2Store(at: url)

        let result = try migrateAndSweep(url)

        expectNothingMergedOrDropped(result, events: 2)
        #expect(Set(result.afterSweep.events.keys) == [seeded.linked.uuid, seeded.plain.uuid])
        #expect(Set(result.afterSweep.templates.keys) == [seeded.templateUUID])
    }

    @Test func sweep_overMigratedV3Store_changesNothing_andKeepsSeededUUIDs() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        let seeded = try MigrationFixtures.seedV3Store(at: url)

        let result = try migrateAndSweep(url)

        expectNothingMergedOrDropped(result, events: 2)
        #expect(Set(result.afterSweep.events.keys) == [seeded.linked.uuid, seeded.plain.uuid])
        #expect(Set(result.afterSweep.templates.keys) == [seeded.templateUUID])
    }

    // Field equality is not identity: three V1 events with identical values (two
    // with the identical timestamp) must each get their own uuid and survive.
    @Test func sweep_overV1EventsWithIdenticalFields_keepsAllThree() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        try MigrationFixtures.seedV1IdenticalEventsStore(at: url)

        let result = try migrateAndSweep(url)

        expectNothingMergedOrDropped(result, events: 3)
        #expect(result.migrated.events.count == 3)
        #expect(result.afterSweep.events.count == 3)
        #expect(Set(result.afterSweep.events.keys).count == 3)
    }

    @Test func sweep_runTwice_leavesExactlyOneProfile() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        _ = try MigrationFixtures.seedV1Store(at: url)

        let result = try migrateAndSweep(url)

        #expect(result.afterSweep.profileCount == 1)
        #expect(result.afterSecondSweep.profileCount == 1)
        #expect(result.afterSecondSweep == result.afterSweep)
    }
}
