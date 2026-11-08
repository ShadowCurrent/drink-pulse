import Foundation
import os
import Testing
@testable import drinkpulse

private struct InterruptedSaveError: Error {}

/// Forwards every call to a wrapped `FakeHealthStore` and records the operation order.
private final class RecordingHealthStore: HealthWriting, @unchecked Sendable {
    enum Op: Equatable { case query, save, delete }
    struct Entry: Equatable {
        let op: Op
        let eventUUID: UUID?
    }

    private struct State {
        var log: [Entry] = []
        var failAfterNextSave = false
    }

    let wrapped: FakeHealthStore
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(wrapped: FakeHealthStore = FakeHealthStore()) {
        self.wrapped = wrapped
    }

    /// Arms a one-shot failure: the next save stores the sample, then throws.
    /// Models a process killed after the HealthKit save but before the cache write.
    func armFailAfterNextSave() {
        state.withLock { $0.failAfterNextSave = true }
    }

    var log: [Entry] { state.withLock { $0.log } }

    func mutatingOps(for eventUUID: UUID? = nil) -> [Op] {
        log.filter { entry in
            entry.op != .query && (eventUUID == nil || entry.eventUUID == eventUUID)
        }.map(\.op)
    }

    private func record(_ op: Op, _ eventUUID: UUID?) {
        state.withLock { $0.log.append(Entry(op: op, eventUUID: eventUUID)) }
    }

    var isHealthDataAvailable: Bool { wrapped.isHealthDataAvailable }

    func requestAuthorization() async throws -> Bool {
        try await wrapped.requestAuthorization()
    }

    func authorizationStatus() -> HealthAuthStatus { wrapped.authorizationStatus() }

    func save(grams: Double, date: Date, eventUUID: UUID) async throws -> UUID {
        record(.save, eventUUID)
        let sample = try await wrapped.save(grams: grams, date: date, eventUUID: eventUUID)
        let shouldFail = state.withLock { state -> Bool in
            let armed = state.failAfterNextSave
            state.failAfterNextSave = false
            return armed
        }
        if shouldFail { throw InterruptedSaveError() }
        return sample
    }

    func sampleUUID(forEventUUID eventUUID: UUID) async throws -> UUID? {
        record(.query, eventUUID)
        return try await wrapped.sampleUUID(forEventUUID: eventUUID)
    }

    func delete(uuid: UUID) async throws {
        let owner = wrapped.samplesByEvent.first { $0.value == uuid }?.key
        record(.delete, owner)
        try await wrapped.delete(uuid: uuid)
    }
}

@MainActor
private final class StartFlag {
    var started = false
}

/// Creates an un-awaited Task and returns it only after the operation has registered
/// in the service's per-event chain, so registration order is deterministic.
/// The Task body sets the flag and calls straight into the service with no suspension
/// point in between.
@MainActor
private func enqueue(_ operation: @escaping @MainActor () async -> Void) async -> Task<Void, Never> {
    let flag = StartFlag()
    let task = Task { @MainActor in
        flag.started = true
        await operation()
    }
    let deadline = ContinuousClock.now.advanced(by: .seconds(2))
    while !flag.started {
        if ContinuousClock.now > deadline {
            Issue.record("Enqueued Health operation did not start within 2 seconds")
            break
        }
        await Task.yield()
    }
    return task
}

@MainActor
struct HealthServiceOrderingTests {

    private func makeEvent() -> ConsumptionEvent {
        ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
    }

    @Test func writeUpdateRemove_executeInEnqueueOrder_forOneEvent() async {
        let store = RecordingHealthStore()
        let service = HealthService(store: store)
        let event = makeEvent()

        let writeTask = await enqueue { await service.write(event) }
        let updateTask = await enqueue { await service.update(event) }
        let removeTask = await enqueue { await service.remove(event) }
        await writeTask.value
        await updateTask.value
        await removeTask.value

        #expect(store.mutatingOps() == [.save, .delete, .save, .delete])
        #expect(store.wrapped.samplesByEvent[event.uuid] == nil)
        #expect(event.healthKitUUID == nil)
    }

    @Test func doubleWrite_savesOneSample_andRelinksSecondCall() async {
        let store = RecordingHealthStore()
        let service = HealthService(store: store)
        let event = makeEvent()

        let first = await enqueue { await service.write(event) }
        let second = await enqueue { await service.write(event) }
        await first.value
        await second.value

        #expect(store.wrapped.saveCount == 1)
        #expect(store.wrapped.samplesByEvent.count == 1)
        #expect(event.healthKitUUID != nil)
        #expect(event.healthKitUUID == store.wrapped.samplesByEvent[event.uuid])
    }

    @Test func operationsOnDifferentEvents_doNotShareAChain() async {
        let store = RecordingHealthStore()
        let service = HealthService(store: store)
        let eventA = makeEvent()
        let eventB = makeEvent()

        let writeA = await enqueue { await service.write(eventA) }
        let writeB = await enqueue { await service.write(eventB) }
        let removeA = await enqueue { await service.remove(eventA) }
        await writeA.value
        await writeB.value
        await removeA.value

        #expect(store.wrapped.samplesByEvent[eventA.uuid] == nil)
        #expect(store.wrapped.samplesByEvent[eventB.uuid] != nil)
        #expect(eventB.healthKitUUID == store.wrapped.samplesByEvent[eventB.uuid])
        #expect(eventA.healthKitUUID == nil)
        #expect(store.mutatingOps(for: eventA.uuid) == [.save, .delete])
    }

    @Test func interruptedWrite_savedButNotCached_relinksOnNextBackfill_noDuplicate() async {
        let store = RecordingHealthStore()
        let service = HealthService(store: store)
        let event = makeEvent()

        store.armFailAfterNextSave()
        await service.write(event)

        #expect(event.healthKitUUID == nil)
        #expect(store.wrapped.samplesByEvent.count == 1)
        let storedSample = store.wrapped.samplesByEvent[event.uuid]
        #expect(storedSample != nil)

        await service.backfill([event])

        #expect(store.wrapped.saveCount == 1)
        #expect(store.wrapped.samplesByEvent.count == 1)
        #expect(event.healthKitUUID == storedSample)
    }
}
