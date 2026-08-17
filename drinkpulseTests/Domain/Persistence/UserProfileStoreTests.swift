import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct UserProfileStoreTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func fetchOrCreate_createsProfile_whenStoreEmpty() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let profile = UserProfileStore.fetchOrCreate(in: context)
        try context.save()

        let all = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(all.count == 1)
        #expect(all.first === profile)
    }

    @Test func fetchOrCreate_savesImmediately_withoutExternalSaveCall() throws {
        let container = try makeContainer()
        let context = container.mainContext
        _ = UserProfileStore.fetchOrCreate(in: context)

        #expect(context.hasChanges == false)
    }

    @Test func fetchOrCreate_isIdempotent_returnsSameProfile() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let first = UserProfileStore.fetchOrCreate(in: context)
        try context.save()
        let second = UserProfileStore.fetchOrCreate(in: context)

        #expect(first === second)
        #expect(try context.fetch(FetchDescriptor<UserProfile>()).count == 1)
    }

    @Test func deduplicated_collapsesToNewestModifiedDate() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let older = UserProfile(bodyWeightKg: 70)
        older.modifiedDate = Date(timeIntervalSince1970: 1_000)
        let newer = UserProfile(bodyWeightKg: 99)
        newer.modifiedDate = Date(timeIntervalSince1970: 9_000)
        context.insert(older)
        context.insert(newer)

        let survivor = UserProfileStore.deduplicated(in: context)
        try context.save()

        let all = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(all.count == 1)
        #expect(survivor === newer)
        #expect(all.first?.bodyWeightKg == 99)
    }

    @Test func deduplicated_returnsNil_whenEmpty() throws {
        let container = try makeContainer()
        let context = container.mainContext
        #expect(UserProfileStore.deduplicated(in: context) == nil)
    }

    @Test func fetchOrCreate_afterDedupe_savesImmediately_withoutExternalSaveCall() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let older = UserProfile(bodyWeightKg: 70)
        older.modifiedDate = Date(timeIntervalSince1970: 1_000)
        let newer = UserProfile(bodyWeightKg: 99)
        newer.modifiedDate = Date(timeIntervalSince1970: 9_000)
        context.insert(older)
        context.insert(newer)
        try context.save()

        _ = UserProfileStore.fetchOrCreate(in: context)

        #expect(context.hasChanges == false)
    }
}
