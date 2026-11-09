import Foundation
import Testing
@testable import drinkpulse

/// Parallel-operation tests for `HealthService` per-event serialization.
///
/// Finding F2 (Phase 10, INT-02/MOD-03): a quick delete queued behind an in-flight edit
/// removes a stale captured sample UUID and leaves the freshly written sample behind.
/// The owner decision lives in 10-DECISION-F2.md; plan 10-08 applies or retains it.
@MainActor
struct HealthServiceConcurrencyTests {

    private func makeEvent() -> ConsumptionEvent {
        ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
    }

    /// Main-actor flag a started Task flips as its very first statement.
    @MainActor
    private final class StartedFlag {
        var isSet = false
    }

    /// Creates an un-awaited Task and returns it only after its operation has registered in
    /// `HealthService.runSerial`'s per-event chain.
    ///
    /// The Task body sets the flag and then calls straight into the service. There is no
    /// suspension point between the two on the main actor, so once the flag is observed the
    /// operation is already queued. Callers that enqueue one operation at a time therefore
    /// fix the registration order by construction, not by the unspecified Task start order.
    /// Polls with `Task.yield` under a 2 second deadline; no fixed sleeps.
    private func enqueue(_ operation: @escaping @MainActor () async -> Void) async -> Task<Void, Never> {
        let flag = StartedFlag()
        let task = Task { @MainActor in
            flag.isSet = true
            await operation()
        }
        let deadline = ContinuousClock.now + .seconds(2)
        while !flag.isSet {
            if ContinuousClock.now >= deadline {
                Issue.record("Enqueued Health operation did not start within 2 seconds")
                break
            }
            await Task.yield()
        }
        return task
    }

    // MARK: - F2 pin

    @Test func removeQueuedBehindInFlightUpdate_leavesNoSample_knownIssueF2() async throws {
        let fake = FakeHealthStore()
        let service = HealthService(store: fake)
        let event = makeEvent()

        await service.write(event)
        let capturedUUID = try #require(event.healthKitUUID)
        #expect(fake.samplesByEvent[event.uuid] == capturedUUID)

        let eventUUID = event.uuid
        let updateTask = await enqueue { await service.update(event) }
        let removeTask = await enqueue {
            await service.removeSample(healthKitUUID: capturedUUID, eventUUID: eventUUID)
        }
        await updateTask.value
        await removeTask.value

        // Finding F2, see 10-DECISION-F2.md (Outcome fix-query-first): the serialized remove
        // resolves the current sample by dp_event_uuid, so the sample update just wrote is
        // deleted even though the captured UUID is stale.
        #expect(fake.samplesByEvent[event.uuid] == nil)
    }

    // MARK: - F2 remove target resolution (10-DECISION-F2.md, fix-query-first)

    @Test func removeSample_deletesStoredSample_whenCapturedUUIDIsStale() async {
        let eventUUID = UUID()
        let stale = UUID()
        let current = UUID()
        let fake = FakeHealthStore(seed: [eventUUID: current])
        let service = HealthService(store: fake)

        await service.removeSample(healthKitUUID: stale, eventUUID: eventUUID)

        #expect(fake.deletedUUIDs == [current])
        #expect(fake.samplesByEvent[eventUUID] == nil)
    }

    @Test func removeSample_fallsBackToCapturedUUID_whenQueryFindsNoSample() async {
        let eventUUID = UUID()
        let captured = UUID()
        let fake = FakeHealthStore()
        let service = HealthService(store: fake)

        await service.removeSample(healthKitUUID: captured, eventUUID: eventUUID)

        #expect(fake.queryCount == 1)
        #expect(fake.deletedUUIDs == [captured])
    }

    @Test func removeSample_fallsBackToCapturedUUID_whenQueryThrows() async {
        let eventUUID = UUID()
        let captured = UUID()
        let fake = FakeHealthStore(seed: [eventUUID: captured])
        fake.throwOnQuery = true
        let service = HealthService(store: fake)

        await service.removeSample(healthKitUUID: captured, eventUUID: eventUUID)

        #expect(fake.queryCount == 1)
        #expect(fake.deletedUUIDs == [captured])
    }

    // MARK: - Control

    @Test func updateThenRemove_awaitedSequentially_leavesNoSample() async throws {
        let fake = FakeHealthStore()
        let service = HealthService(store: fake)
        let event = makeEvent()

        await service.write(event)
        let originalUUID = try #require(event.healthKitUUID)

        await service.update(event)
        let replacementUUID = try #require(event.healthKitUUID)
        #expect(replacementUUID != originalUUID)

        await service.remove(event)

        #expect(fake.samplesByEvent[event.uuid] == nil)
        #expect(event.healthKitUUID == nil)
        #expect(fake.deletedUUIDs == [originalUUID, replacementUUID])
    }
}
