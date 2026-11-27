import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// V4 to V5 (quick 261127-l7y): the lightweight stage drops the stored date of birth and
/// keeps every other field, identity and clock, with no store recovery.
@MainActor
struct MigrationV4ToV5Tests {

    @Test func v4Store_migratesToV5_dropsDateOfBirth_keepsEverythingElse() throws {
        let url = MigrationFixtures.makeTempStoreURL()
        defer { MigrationFixtures.removeStoreFiles(at: url) }
        let seeded = try MigrationFixtures.seedV4Store(at: url)

        let schema = MigrationFixtures.liveSchema()
        let (container, didRecover) = try StoreBootstrap.makeContainerReportingRecovery(
            schema: schema, configuration: MigrationFixtures.liveConfiguration(at: url), recoveryRoot: nil
        )
        let context = container.mainContext

        #expect(!didRecover)
        #expect(try context.fetchCount(FetchDescriptor<ConsumptionEvent>()) == 2)
        #expect(try context.fetchCount(FetchDescriptor<DrinkTemplate>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<UserProfile>()) == 1)

        let profile = try #require(try context.fetch(FetchDescriptor<UserProfile>()).first)
        #expect(profile.id == "singleton")
        #expect(ProfileValues(profile) == seeded.profile)
        #expect(profile.modifiedDate == seeded.profileModifiedDate)

        let template = try #require(try context.fetch(FetchDescriptor<DrinkTemplate>()).first)
        #expect(template.uuid == seeded.templateUUID)
        #expect(template.modifiedDate == seeded.templateModifiedDate)
        #expect(TemplateValues(template) == seeded.template)

        let events = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        for (expected, healthKitUUID) in [(seeded.linked, Optional(seeded.linkedHealthKitUUID)), (seeded.plain, nil)] {
            let live = try #require(events.first { $0.uuid == expected.uuid })
            #expect(live.consumptionDate == expected.consumptionDate)
            #expect(live.creationDate == expected.creationDate)
            #expect(live.modifiedDate == expected.modifiedDate)
            #expect(live.healthKitUUID == healthKitUUID)
            #expect(EventValues(live) == expected.values)
        }
        let linked = try #require(events.first { $0.uuid == seeded.linked.uuid })
        let plain = try #require(events.first { $0.uuid == seeded.plain.uuid })
        #expect(linked.template?.uuid == seeded.templateUUID)
        #expect(plain.template == nil)
    }

    @Test func schemaV5_userProfile_hasNoDateOfBirth_whileV4Keeps() throws {
        let v4 = try #require(Schema(versionedSchema: SchemaV4.self).entitiesByName["UserProfile"])
        let v5 = try #require(Schema(versionedSchema: SchemaV5.self).entitiesByName["UserProfile"])
        #expect(v4.storedPropertiesByName["dateOfBirth"] != nil)
        #expect(v5.storedPropertiesByName["dateOfBirth"] == nil)
        #expect(SchemaV5.versionIdentifier == Schema.Version(5, 0, 0))
    }
}
