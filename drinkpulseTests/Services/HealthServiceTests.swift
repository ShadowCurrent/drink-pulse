import Foundation
import Testing
@testable import drinkpulse

/// Unit tests for `HealthService` (plan-0036 W3), driven by the configurable
/// `FakeHealthStore` (see `FakeHealthStore.swift`). Covers availability/auth
/// gating, write+dedup, update, remove, backfill idempotency, and that every
/// error path is swallowed without throwing while the event stays consistent.
@MainActor
struct HealthServiceTests {

    private func makeEvent() -> ConsumptionEvent {
        // 500 ml @ 5% → 19.725 g physical (0.789).
        ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
    }

    // MARK: - Availability / authorization gating

    @Test func write_doesNothing_whenHealthUnavailable() async {
        let fake = FakeHealthStore()
        fake.available = false
        let service = HealthService(store: fake)
        let event = makeEvent()

        await service.write(event)

        #expect(fake.saveCount == 0)
        #expect(event.healthKitUUID == nil)
    }

    @Test func write_doesNothing_whenDenied() async {
        let fake = FakeHealthStore()
        fake.status = .denied
        let service = HealthService(store: fake)
        let event = makeEvent()

        await service.write(event)

        #expect(fake.saveCount == 0)
        #expect(event.healthKitUUID == nil)
    }

    @Test func write_doesNothing_whenNotDetermined() async {
        let fake = FakeHealthStore()
        fake.status = .notDetermined
        let service = HealthService(store: fake)
        let event = makeEvent()

        await service.write(event)

        #expect(fake.saveCount == 0)
        #expect(event.healthKitUUID == nil)
    }

    // MARK: - write

    @Test func write_savesOnce_andStoresHealthKitUUID_whenAuthorizedAndNew() async {
        let fake = FakeHealthStore()
        let service = HealthService(store: fake)
        let event = makeEvent()

        await service.write(event)

        #expect(fake.saveCount == 1)
        #expect(event.healthKitUUID != nil)
        #expect(fake.samplesByEvent[event.uuid] == event.healthKitUUID)
        #expect(fake.savedGrams.first == event.pureAlcoholGrams)
    }

    @Test func write_relinksWithoutDuplicate_whenSampleAlreadyExists() async {
        let event = makeEvent()
        let existing = UUID()
        let fake = FakeHealthStore(seed: [event.uuid: existing])
        let service = HealthService(store: fake)

        await service.write(event)

        #expect(fake.saveCount == 0)
        #expect(event.healthKitUUID == existing)
    }

    // MARK: - update

    @Test func update_deletesOldSample_thenWritesFresh() async {
        let event = makeEvent()
        let old = UUID()
        let fake = FakeHealthStore(seed: [event.uuid: old])
        event.healthKitUUID = old
        let service = HealthService(store: fake)

        await service.update(event)

        #expect(fake.deleteCount == 1)
        #expect(fake.deletedUUIDs == [old])
        #expect(fake.saveCount == 1)
        #expect(event.healthKitUUID != nil)
        #expect(event.healthKitUUID != old)
    }

    @Test func update_writesFresh_whenNoPriorSample() async {
        let fake = FakeHealthStore()
        let service = HealthService(store: fake)
        let event = makeEvent()

        await service.update(event)

        #expect(fake.deleteCount == 0)
        #expect(fake.saveCount == 1)
        #expect(event.healthKitUUID != nil)
    }

    @Test func update_whenDeleteFails_relinksSurvivingSample_noDuplicate() async {
        let event = makeEvent()
        let old = UUID()
        let fake = FakeHealthStore(seed: [event.uuid: old])
        fake.throwOnDelete = true
        event.healthKitUUID = old
        let service = HealthService(store: fake)

        await service.update(event)

        // Delete throws (swallowed) so the old sample survives; the follow-up
        // write's dedup query then finds it → relink, never a duplicate write.
        #expect(fake.deleteCount == 1)
        #expect(fake.saveCount == 0)
        #expect(event.healthKitUUID == old)
    }

    // MARK: - remove

    @Test func remove_deletesByCachedUUID_andClearsField() async {
        let event = makeEvent()
        let sample = UUID()
        let fake = FakeHealthStore(seed: [event.uuid: sample])
        event.healthKitUUID = sample
        let service = HealthService(store: fake)

        await service.remove(event)

        #expect(fake.deleteCount == 1)
        #expect(fake.deletedUUIDs == [sample])
        #expect(event.healthKitUUID == nil)
    }

    @Test func remove_deletesByQuery_whenCacheIsNil() async {
        let event = makeEvent()
        let sample = UUID()
        let fake = FakeHealthStore(seed: [event.uuid: sample])
        // healthKitUUID intentionally nil → service must find the sample by query.
        let service = HealthService(store: fake)

        await service.remove(event)

        #expect(fake.queryCount == 1)
        #expect(fake.deletedUUIDs == [sample])
        #expect(event.healthKitUUID == nil)
    }

    @Test func remove_noOps_whenNoSampleExists() async {
        let fake = FakeHealthStore()
        let service = HealthService(store: fake)
        let event = makeEvent()

        await service.remove(event)

        #expect(fake.deleteCount == 0)
        #expect(event.healthKitUUID == nil)
    }

    // MARK: - backfill

    @Test func backfill_writesEveryEvent() async {
        let fake = FakeHealthStore()
        let service = HealthService(store: fake)
        let events = [makeEvent(), makeEvent(), makeEvent()]

        await service.backfill(events)

        #expect(fake.saveCount == 3)
        #expect(events.allSatisfy { $0.healthKitUUID != nil })
    }

    @Test func backfill_isIdempotent_onSecondRun() async {
        let fake = FakeHealthStore()
        let service = HealthService(store: fake)
        let events = [makeEvent(), makeEvent()]

        await service.backfill(events)
        #expect(fake.saveCount == 2)

        // Second run finds existing samples by metadata → relink, no new writes.
        await service.backfill(events)
        #expect(fake.saveCount == 2)
    }

    // MARK: - Error paths (swallowed, never thrown; event stays consistent)

    @Test func write_swallowsSaveError_andLeavesUUIDNil() async {
        let fake = FakeHealthStore()
        fake.throwOnSave = true
        let service = HealthService(store: fake)
        let event = makeEvent()

        await service.write(event)

        #expect(fake.saveCount == 1)
        #expect(event.healthKitUUID == nil)
    }

    @Test func remove_swallowsDeleteError_andStillClearsField() async {
        let event = makeEvent()
        let sample = UUID()
        let fake = FakeHealthStore(seed: [event.uuid: sample])
        fake.throwOnDelete = true
        event.healthKitUUID = sample
        let service = HealthService(store: fake)

        await service.remove(event)

        #expect(fake.deleteCount == 1)
        #expect(event.healthKitUUID == nil)
    }

    @Test func write_swallowsQueryError_andLeavesUUIDNil() async {
        let fake = FakeHealthStore()
        fake.throwOnQuery = true
        let service = HealthService(store: fake)
        let event = makeEvent()

        await service.write(event)

        #expect(event.healthKitUUID == nil)
    }

    // MARK: - Authorization API

    @Test func requestAuthorization_returnsGranted() async {
        let fake = FakeHealthStore()
        fake.authResult = true
        let service = HealthService(store: fake)

        #expect(await service.requestAuthorization() == true)
    }

    @Test func requestAuthorization_returnsFalse_onError() async {
        let fake = FakeHealthStore()
        fake.authError = FakeHealthError.auth
        let service = HealthService(store: fake)

        #expect(await service.requestAuthorization() == false)
    }

    @Test func authorizationStatus_passesThroughStoreState() async {
        let fake = FakeHealthStore()
        fake.status = .denied
        let service = HealthService(store: fake)

        #expect(service.authorizationStatus() == .denied)
    }

    // MARK: - Serialization

    @Test func writeThenRemove_serialized_leavesConsistentState() async {
        let fake = FakeHealthStore()
        let service = HealthService(store: fake)
        let event = makeEvent()

        await service.write(event)
        await service.remove(event)

        #expect(fake.saveCount == 1)
        #expect(fake.deleteCount == 1)
        #expect(event.healthKitUUID == nil)
        #expect(fake.samplesByEvent[event.uuid] == nil)
    }

    // MARK: - Production wiring

    @Test func defaultInit_buildsServiceFromFactoryStore() {
        // Exercises the convenience init + defaultStore() factory (selects the
        // real adapter outside UI tests). Constructing it must not crash and must
        // expose a queryable authorization state.
        let service = HealthService()

        _ = service.authorizationStatus()
        #expect(Bool(true))
    }
}
