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

        // Finding F2, see 10-DECISION-F2.md: remove deletes the captured (already replaced)
        // UUID, so the sample update just wrote survives. Remove this wrapper only together
        // with the owner-approved fix in plan 10-08.
        withKnownIssue("F2: orphan Health sample after edit then quick delete (10-DECISION-F2.md)") {
            #expect(fake.samplesByEvent[event.uuid] == nil)
        }
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
