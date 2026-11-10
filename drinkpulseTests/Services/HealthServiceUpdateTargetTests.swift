import Foundation
import Testing
@testable import drinkpulse

/// `HealthService.update` must resolve the current sample by dp_event_uuid before it deletes,
/// because the device-local `healthKitUUID` cache can be nil or stale (review finding WR-01).
@MainActor
struct HealthServiceUpdateTargetTests {

    private func makeEvent() -> ConsumptionEvent {
        ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
    }

    @Test func update_replacesExistingSample_whenCachedUUIDIsNil() async {
        let event = makeEvent()
        let existing = UUID()
        let fake = FakeHealthStore(seed: [event.uuid: existing])
        let service = HealthService(store: fake)

        await service.update(event)

        #expect(fake.deletedUUIDs == [existing])
        #expect(fake.saveCount == 1)
        #expect(fake.savedGrams == [event.pureAlcoholGrams])
        #expect(event.healthKitUUID == fake.samplesByEvent[event.uuid])
        #expect(event.healthKitUUID != existing)
    }

    @Test func update_deletesCurrentSample_whenCachedUUIDIsStale() async {
        let event = makeEvent()
        let stale = UUID()
        let current = UUID()
        let fake = FakeHealthStore(seed: [event.uuid: current])
        event.healthKitUUID = stale
        let service = HealthService(store: fake)

        await service.update(event)

        #expect(fake.deletedUUIDs == [current])
        #expect(fake.saveCount == 1)
        #expect(event.healthKitUUID == fake.samplesByEvent[event.uuid])
        #expect(event.healthKitUUID != current)
    }

    @Test func update_deletesCachedUUID_whenQueryFindsNoSample() async {
        let event = makeEvent()
        let cached = UUID()
        let fake = FakeHealthStore()
        event.healthKitUUID = cached
        let service = HealthService(store: fake)

        await service.update(event)

        #expect(fake.deletedUUIDs == [cached])
        #expect(fake.saveCount == 1)
        #expect(event.healthKitUUID != nil)
        #expect(event.healthKitUUID != cached)
    }

    @Test func update_writesNothing_whenLookupThrows() async {
        let event = makeEvent()
        let cached = UUID()
        let fake = FakeHealthStore(seed: [event.uuid: cached])
        fake.throwOnQuery = true
        event.healthKitUUID = cached
        let service = HealthService(store: fake)

        await service.update(event)

        #expect(fake.deleteCount == 0)
        #expect(fake.saveCount == 0)
        #expect(event.healthKitUUID == cached)
    }

    @Test func update_whenDeleteFails_keepsCachedUUID_andWritesNothing() async {
        let event = makeEvent()
        let existing = UUID()
        let fake = FakeHealthStore(seed: [event.uuid: existing])
        fake.throwOnDelete = true
        let service = HealthService(store: fake)

        await service.update(event)

        #expect(fake.deleteCount == 1)
        #expect(fake.saveCount == 0)
        #expect(fake.samplesByEvent[event.uuid] == existing)
    }
}
