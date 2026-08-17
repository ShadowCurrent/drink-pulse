import Foundation
import SwiftData
import Testing
@testable import drinkpulse

@MainActor
@Suite(.serialized)
struct HealthWriteHooksTests {

    private func withWriteEnabled(_ enabled: Bool, _ body: () async throws -> Void) async rethrows {
        let key = AppStorageKeys.healthWriteEnabled
        let previous = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.set(enabled, forKey: key)
        defer {
            if let previous { UserDefaults.standard.set(previous, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        try await body()
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeEvent() -> ConsumptionEvent {
        ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
    }

    @Test func write_invokesService_andStampsUUID_whenEnabled() async throws {
        try await withWriteEnabled(true) {
            let fake = FakeHealthStore()
            let service = HealthService(store: fake)
            let container = try makeContainer()
            let context = container.mainContext
            let event = makeEvent()
            context.insert(event)

            await HealthWriteHooks.write(event, in: context, using: service)?.value

            #expect(fake.saveCount == 1)
            #expect(event.healthKitUUID != nil)
        }
    }

    @Test func write_noOps_whenDisabled() async throws {
        try await withWriteEnabled(false) {
            let fake = FakeHealthStore()
            let service = HealthService(store: fake)
            let container = try makeContainer()
            let context = container.mainContext
            let event = makeEvent()
            context.insert(event)

            let task = HealthWriteHooks.write(event, in: context, using: service)

            #expect(task == nil)
            #expect(fake.saveCount == 0)
            #expect(event.healthKitUUID == nil)
        }
    }

    @Test func write_noOps_whenNoService() async throws {
        try await withWriteEnabled(true) {
            let container = try makeContainer()
            let context = container.mainContext
            let event = makeEvent()
            context.insert(event)

            let task = HealthWriteHooks.write(event, in: context, using: nil)

            #expect(task == nil)
            #expect(event.healthKitUUID == nil)
        }
    }

    @Test func update_invokesService_andStampsUUID_whenEnabled() async throws {
        try await withWriteEnabled(true) {
            let event = makeEvent()
            let old = UUID()
            let fake = FakeHealthStore(seed: [event.uuid: old])
            event.healthKitUUID = old
            let service = HealthService(store: fake)
            let container = try makeContainer()
            let context = container.mainContext
            context.insert(event)

            await HealthWriteHooks.update(event, in: context, using: service)?.value

            #expect(fake.deleteCount == 1)
            #expect(fake.saveCount == 1)
            #expect(event.healthKitUUID != nil)
            #expect(event.healthKitUUID != old)
        }
    }

    @Test func update_noOps_whenDisabled() async throws {
        try await withWriteEnabled(false) {
            let fake = FakeHealthStore()
            let service = HealthService(store: fake)
            let container = try makeContainer()
            let context = container.mainContext
            let event = makeEvent()
            context.insert(event)

            let task = HealthWriteHooks.update(event, in: context, using: service)

            #expect(task == nil)
            #expect(fake.saveCount == 0)
        }
    }

    @Test func remove_invokesService_whenEnabled() async throws {
        try await withWriteEnabled(true) {
            let event = makeEvent()
            let sample = UUID()
            let fake = FakeHealthStore(seed: [event.uuid: sample])
            event.healthKitUUID = sample
            let service = HealthService(store: fake)

            await HealthWriteHooks.remove(event, using: service)?.value

            #expect(fake.deleteCount == 1)
            #expect(fake.deletedUUIDs == [sample])
        }
    }
}
