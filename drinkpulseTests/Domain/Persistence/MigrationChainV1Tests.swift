import Testing
import Foundation
import SwiftData
@testable import drinkpulse

// V1 had no uuid and a `name` field that V2 dropped by design (ADR-0010), so no
// test here compares uuid or `name` across the V1 boundary.
@MainActor
struct MigrationChainV1Tests {

    private func open(_ url: URL) throws -> (container: ModelContainer, didRecover: Bool) {
        let schema = MigrationFixtures.liveSchema()
        let config = ModelConfiguration(schema: schema, url: url)
        return try StoreBootstrap.makeContainerReportingRecovery(schema: schema, configuration: config)
    }

    private func sortedEvents(_ context: ModelContext) throws -> [ConsumptionEvent] {
        try context.fetch(FetchDescriptor<ConsumptionEvent>(
            sortBy: [SortDescriptor(\.consumptionDate)]
        ))
    }

    @Test func v1Store_opensWithoutRecovery_andKeepsAllRecords() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        _ = try MigrationFixtures.seedV1Store(at: url)

        let (container, didRecover) = try open(url)

        #expect(!didRecover)
        #expect(FileManager.default.fileExists(atPath: url.path))
        let context = container.mainContext
        #expect(try context.fetchCount(FetchDescriptor<ConsumptionEvent>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<DrinkTemplate>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<UserProfile>()) == 1)
    }

    @Test func v1Events_keepEveryStoredValue_andDeriveIdentityAndClocks() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        let seeded = try MigrationFixtures.seedV1Store(at: url)

        let (container, didRecover) = try open(url)

        #expect(!didRecover)
        #expect(FileManager.default.fileExists(atPath: url.path))
        let events = try sortedEvents(container.mainContext)
        try #require(events.count == 2)
        let a = events[0]
        let b = events[1]

        #expect(EventValues(a) == seeded.eventA)
        #expect(EventValues(b) == seeded.eventB)
        #expect(abs(a.consumptionDate.timeIntervalSince(seeded.timestampA)) < 1)
        #expect(abs(b.consumptionDate.timeIntervalSince(seeded.timestampB)) < 1)
        for event in events {
            #expect(abs(event.creationDate.timeIntervalSince(event.consumptionDate)) < 1)
            #expect(abs(event.modifiedDate.timeIntervalSince(event.consumptionDate)) < 1)
            #expect(event.healthKitUUID == nil)
        }
        let templates = try container.mainContext.fetch(FetchDescriptor<DrinkTemplate>())
        let template = try #require(templates.first)
        #expect(Set([a.uuid, b.uuid, template.uuid]).count == 3)
        #expect(a.template?.uuid == template.uuid)
        #expect(b.template == nil)
    }

    @Test func v1TemplateAndProfile_keepEveryStoredValue_andStampFreshClocks() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        let seeded = try MigrationFixtures.seedV1Store(at: url)

        let windowStart = Date.now.addingTimeInterval(-1)
        let (container, didRecover) = try open(url)
        let windowEnd = Date.now.addingTimeInterval(1)

        #expect(!didRecover)
        #expect(FileManager.default.fileExists(atPath: url.path))
        let context = container.mainContext
        let templates = try context.fetch(FetchDescriptor<DrinkTemplate>())
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        let template = try #require(templates.first)
        let profile = try #require(profiles.first)
        let epoch = Date(timeIntervalSince1970: 0)

        #expect(TemplateValues(template) == seeded.template)
        #expect(template.events.count == 1)
        #expect(template.events.first?.volumeMl == seeded.eventA.volumeMl)
        #expect(template.modifiedDate != epoch)
        #expect(template.modifiedDate >= windowStart && template.modifiedDate <= windowEnd)

        #expect(ProfileValues(profile) == seeded.profile)
        #expect(profile.id == "singleton")
        #expect(profile.modifiedDate != epoch)
        #expect(profile.modifiedDate >= windowStart && profile.modifiedDate <= windowEnd)
    }

    @Test func v1Store_reopenedAfterMigration_isUnchangedAndDoesNotRecover() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        _ = try MigrationFixtures.seedV1Store(at: url)

        let first: StoreSnapshot
        do {
            let (container, didRecover) = try open(url)
            #expect(!didRecover)
            first = try StoreSnapshot.take(from: container.mainContext)
        }

        let (reopened, didRecoverSecond) = try open(url)

        #expect(!didRecoverSecond)
        #expect(FileManager.default.fileExists(atPath: url.path))
        let second = try StoreSnapshot.take(from: reopened.mainContext)
        #expect(second == first)
        #expect(second.eventCount == 2 && second.templateCount == 1 && second.profileCount == 1)
    }
}
