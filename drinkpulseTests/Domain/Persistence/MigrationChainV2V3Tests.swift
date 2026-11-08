import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct MigrationChainV2V3Tests {

    private func open(_ url: URL) throws -> (container: ModelContainer, didRecover: Bool) {
        let schema = MigrationFixtures.liveSchema()
        let config = ModelConfiguration(schema: schema, url: url)
        return try StoreBootstrap.makeContainerReportingRecovery(schema: schema, configuration: config)
    }

    private func event(withUUID uuid: UUID, in context: ModelContext) throws -> ConsumptionEvent {
        let events = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        return try #require(events.first { $0.uuid == uuid })
    }

    /// Every stored property of every record equals what was seeded, except
    /// creationDate which the expectation already carries in its migrated form.
    private func expectMigrated(_ context: ModelContext, matches seeded: LegacyExpectation) throws {
        #expect(try context.fetchCount(FetchDescriptor<ConsumptionEvent>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<DrinkTemplate>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<UserProfile>()) == 1)

        for expected in [seeded.linked, seeded.plain] {
            let live = try event(withUUID: expected.uuid, in: context)
            #expect(live.uuid == expected.uuid)
            #expect(live.consumptionDate == expected.consumptionDate)
            #expect(live.creationDate == expected.creationDate)
            #expect(live.modifiedDate == expected.modifiedDate)
            #expect(live.healthKitUUID == nil)
            #expect(EventValues(live) == expected.values)
        }
        let linkedLive = try event(withUUID: seeded.linked.uuid, in: context)
        let plainLive = try event(withUUID: seeded.plain.uuid, in: context)

        let template = try #require(try context.fetch(FetchDescriptor<DrinkTemplate>()).first)
        #expect(template.uuid == seeded.templateUUID)
        #expect(template.modifiedDate == seeded.templateModifiedDate)
        #expect(TemplateValues(template) == seeded.template)
        #expect(linkedLive.template?.uuid == seeded.templateUUID)
        #expect(plainLive.template == nil)
        #expect(template.events.map(\.uuid) == [seeded.linked.uuid])

        let profile = try #require(try context.fetch(FetchDescriptor<UserProfile>()).first)
        #expect(profile.id == "singleton")
        #expect(profile.modifiedDate == seeded.profileModifiedDate)
        #expect(ProfileValues(profile) == seeded.profile)
    }

    @Test func v2Store_migratesToV4_preservingIdentityAndDerivingCreationDate() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        let seeded = try MigrationFixtures.seedV2Store(at: url)

        let (container, didRecover) = try open(url)

        #expect(!didRecover)
        #expect(FileManager.default.fileExists(atPath: url.path))
        try expectMigrated(container.mainContext, matches: seeded)
        // V2 had no creationDate: v2ToV3 derives it from consumptionDate.
        #expect(seeded.linked.creationDate == seeded.linked.consumptionDate)
        #expect(seeded.plain.creationDate == seeded.plain.consumptionDate)
    }

    @Test func v3Store_migratesToV4_keepingCreationDateDistinctFromConsumptionDate() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        let seeded = try MigrationFixtures.seedV3Store(at: url)
        // Guard against a vacuous check: the seed must differ from the derived value.
        #expect(seeded.linked.creationDate != seeded.linked.consumptionDate)

        let (container, didRecover) = try open(url)

        #expect(!didRecover)
        #expect(FileManager.default.fileExists(atPath: url.path))
        try expectMigrated(container.mainContext, matches: seeded)
    }

    @Test func v2AndV3Profiles_keepSingletonIdAndEveryField() throws {
        let v2URL = MigrationFixtures.makeTempStoreURL()
        let v3URL = MigrationFixtures.makeTempStoreURL()
        defer {
            MigrationFixtures.removeStoreFiles(at: v2URL)
            MigrationFixtures.removeStoreFiles(at: v3URL)
        }
        let v2 = try MigrationFixtures.seedV2Store(at: v2URL)
        let v3 = try MigrationFixtures.seedV3Store(at: v3URL)

        for (url, seeded) in [(v2URL, v2), (v3URL, v3)] {
            let (container, didRecover) = try open(url)
            #expect(!didRecover)
            let profiles = try container.mainContext.fetch(FetchDescriptor<UserProfile>())
            let profile = try #require(profiles.first)
            #expect(profiles.count == 1)
            #expect(profile.id == "singleton")
            #expect(ProfileValues(profile) == seeded.profile)
            #expect(profile.modifiedDate == seeded.profileModifiedDate)
        }
    }

    // R-01 seam-level evidence. A real process kill during a migration cannot be
    // reproduced on demand, so this simulates the state an interrupted write can
    // leave behind (an unreadable store file) and proves the seam reports recovery
    // and that a usable store replaces it. It also proves didRecover can be true,
    // so the `!didRecover` assertions elsewhere cannot pass vacuously.
    @Test func corruptedStore_reportsRecoveryAndOpensFresh() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        _ = try MigrationFixtures.seedV3Store(at: url)

        let handle = try FileHandle(forWritingTo: url)
        try handle.write(contentsOf: Data(repeating: 0x5A, count: 100))
        try handle.close()

        let (container, didRecover) = try open(url)

        #expect(didRecover)
        let context = container.mainContext
        #expect(try context.fetchCount(FetchDescriptor<ConsumptionEvent>()) == 0)
        context.insert(ConsumptionEvent(volumeMl: 330, abv: 0.05, category: .beer, icon: "🍺"))
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<ConsumptionEvent>()) == 1)
    }
}
