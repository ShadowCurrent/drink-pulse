import Foundation
import Testing
@testable import drinkpulse

@MainActor
struct HealthServiceRemoveSampleTests {

    @Test func removeSample_deletesSample_whenCachedUUIDMatchesStoredSample() async {
        let eventUUID = UUID()
        let sample = UUID()
        let fake = FakeHealthStore(seed: [eventUUID: sample])
        let service = HealthService(store: fake)

        await service.removeSample(healthKitUUID: sample, eventUUID: eventUUID)

        // F2 (10-DECISION-F2.md): the serialized remove always resolves the current sample by
        // dp_event_uuid first, so a matching cache still costs exactly one query.
        #expect(fake.queryCount == 1)
        #expect(fake.deletedUUIDs == [sample])
    }

    @Test func removeSample_deletesByQuery_whenCachedUUIDIsNil() async {
        let eventUUID = UUID()
        let sample = UUID()
        let fake = FakeHealthStore(seed: [eventUUID: sample])
        let service = HealthService(store: fake)

        await service.removeSample(healthKitUUID: nil, eventUUID: eventUUID)

        #expect(fake.queryCount == 1)
        #expect(fake.deletedUUIDs == [sample])
    }

    @Test func removeSample_noOps_whenNoSampleExists() async {
        let fake = FakeHealthStore()
        let service = HealthService(store: fake)

        await service.removeSample(healthKitUUID: nil, eventUUID: UUID())

        #expect(fake.deleteCount == 0)
    }

    @Test func removeSample_swallowsDeleteError() async {
        let eventUUID = UUID()
        let sample = UUID()
        let fake = FakeHealthStore(seed: [eventUUID: sample])
        fake.throwOnDelete = true
        let service = HealthService(store: fake)

        await service.removeSample(healthKitUUID: sample, eventUUID: eventUUID)

        #expect(fake.deleteCount == 1)
    }

    @Test func removeSample_doesNothing_whenDenied() async {
        let eventUUID = UUID()
        let sample = UUID()
        let fake = FakeHealthStore(seed: [eventUUID: sample])
        fake.status = .denied
        let service = HealthService(store: fake)

        await service.removeSample(healthKitUUID: sample, eventUUID: eventUUID)

        #expect(fake.deleteCount == 0)
    }
}
