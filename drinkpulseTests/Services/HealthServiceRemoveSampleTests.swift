import Foundation
import Testing
@testable import drinkpulse

/// Unit tests for `HealthService.removeSample(healthKitUUID:eventUUID:)` — the
/// value-based delete path the W5 hooks use so they can capture identifiers
/// BEFORE `context.delete` invalidates the `@Model` (plan-0036, W5). Driven by
/// `FakeHealthStore`. Split from `HealthServiceTests` to stay under the 300-line
/// ceiling.
@MainActor
struct HealthServiceRemoveSampleTests {

    @Test func removeSample_deletesByCachedUUID() async {
        let eventUUID = UUID()
        let sample = UUID()
        let fake = FakeHealthStore(seed: [eventUUID: sample])
        let service = HealthService(store: fake)

        // Caller captured the cached UUID before deleting the @Model.
        await service.removeSample(healthKitUUID: sample, eventUUID: eventUUID)

        #expect(fake.queryCount == 0)
        #expect(fake.deletedUUIDs == [sample])
    }

    @Test func removeSample_deletesByQuery_whenCachedUUIDIsNil() async {
        let eventUUID = UUID()
        let sample = UUID()
        let fake = FakeHealthStore(seed: [eventUUID: sample])
        let service = HealthService(store: fake)

        // No cached UUID → relink by dp_event_uuid metadata query, then delete.
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

        // Must not throw; the failed delete leaves a harmless orphan sample.
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
