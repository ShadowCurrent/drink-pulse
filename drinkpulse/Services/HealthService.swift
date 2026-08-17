import Foundation
import OSLog

@MainActor
final class HealthService {
    private let store: HealthWriting
    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "HealthService")

    private var tails: [UUID: ChainBox] = [:]

    private final class ChainBox {
        var task: Task<Void, Never>?
    }

    init(store: HealthWriting) {
        self.store = store
    }

    convenience init() {
        self.init(store: HealthService.defaultStore())
    }

    static func defaultStore() -> HealthWriting {
        UITestSeed.isActive ? UITestHealthStore() : HealthKitAdapter()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            return try await store.requestAuthorization()
        } catch {
            logger.error("Health authorization request failed: \(error.localizedDescription)")
            return false
        }
    }

    func authorizationStatus() -> HealthAuthStatus {
        store.authorizationStatus()
    }

    // MARK: - Mutations (best-effort, serialized per event uuid)

    func write(_ event: ConsumptionEvent) async {
        await runSerial(event.uuid) { [weak self] in
            await self?.performWrite(event)
        }
    }

    func update(_ event: ConsumptionEvent) async {
        await runSerial(event.uuid) { [weak self] in
            await self?.performUpdate(event)
        }
    }

    func remove(_ event: ConsumptionEvent) async {
        await runSerial(event.uuid) { [weak self] in
            await self?.performRemove(event)
        }
    }

    func removeSample(healthKitUUID: UUID?, eventUUID: UUID) async {
        await runSerial(eventUUID) { [weak self] in
            await self?.performRemoveSample(healthKitUUID: healthKitUUID, eventUUID: eventUUID)
        }
    }

    func backfill(_ events: [ConsumptionEvent]) async {
        for event in events {
            await write(event)
        }
    }

    // MARK: - Implementations

    private func isAuthorizedForWrite() async -> Bool {
        guard store.isHealthDataAvailable else {
            logger.notice("Health op skipped: HealthKit unavailable")
            return false
        }
        if authorizationStatus() == .authorized { return true }
        if authorizationStatus() == .notDetermined {
            _ = await requestAuthorization()
            if authorizationStatus() == .authorized { return true }
        }
        logger.notice("Health op skipped: write not authorized")
        return false
    }

    private func performWrite(_ event: ConsumptionEvent) async {
        guard await isAuthorizedForWrite() else { return }
        do {
            if let existing = try await store.sampleUUID(forEventUUID: event.uuid) {
                event.healthKitUUID = existing
                return
            }
            event.healthKitUUID = try await store.save(
                grams: event.pureAlcoholGrams,
                date: event.consumptionDate,
                eventUUID: event.uuid
            )
        } catch {
            logger.error("Health write failed: \(error.localizedDescription)")
        }
    }

    private func performUpdate(_ event: ConsumptionEvent) async {
        guard await isAuthorizedForWrite() else { return }
        if let old = event.healthKitUUID {
            do {
                try await store.delete(uuid: old)
            } catch {
                logger.error("Health update delete failed: \(error.localizedDescription)")
            }
            event.healthKitUUID = nil
        }
        await performWrite(event)
    }

    private func performRemove(_ event: ConsumptionEvent) async {
        await performRemoveSample(healthKitUUID: event.healthKitUUID, eventUUID: event.uuid)
        event.healthKitUUID = nil
    }

    private func performRemoveSample(healthKitUUID: UUID?, eventUUID: UUID) async {
        guard await isAuthorizedForWrite() else { return }
        do {
            var target = healthKitUUID
            if target == nil {
                target = try await store.sampleUUID(forEventUUID: eventUUID)
            }
            if let target {
                try await store.delete(uuid: target)
            }
        } catch {
            logger.error("Health remove failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Per-event serialization

    private func runSerial(_ id: UUID, _ work: @MainActor @escaping () async -> Void) async {
        let previous = tails[id]?.task
        let box = ChainBox()
        let task = Task { @MainActor in
            await previous?.value
            await work()
        }
        box.task = task
        tails[id] = box
        await task.value
        if tails[id] === box {
            tails[id] = nil
        }
    }
}
