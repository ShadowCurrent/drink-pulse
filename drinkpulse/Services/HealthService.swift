import Foundation
import OSLog

/// Mirrors logged drinks into Apple Health as `numberOfAlcoholicBeverages`
/// samples (plan-0036, ADR-0011). Second member of the `Services/` layer
/// (ADR-0008): orchestrates the platform capability through the injected
/// `HealthWriting` protocol so the logic is unit-testable without HealthKit.
///
/// **Best-effort, non-blocking.** Every Health operation catches its errors,
/// logs only a category (never grams / dates / UUIDs — no PII), and never
/// throws into the caller's UI flow. A Health failure must not block or roll
/// back the in-app log/edit/delete; the in-app store stays the source of truth.
///
/// **Persistence ownership.** This service MUTATES the passed
/// `ConsumptionEvent.healthKitUUID` (a device-local cache) but does NOT own a
/// `ModelContext` — per the architecture rule, the caller saves its own
/// context after invoking these methods.
@MainActor
final class HealthService {
    private let store: HealthWriting
    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "HealthService")

    /// Per-event serial chains. A rapid edit→delete enqueues onto the same
    /// event's chain so two ops on one `event.uuid` can never race (the second
    /// awaits the first). Boxed so we can compare identity for tail cleanup.
    private var tails: [UUID: ChainBox] = [:]

    private final class ChainBox {
        var task: Task<Void, Never>?
    }

    init(store: HealthWriting) {
        self.store = store
    }

    /// Production entry point — selects the real adapter or the UI-test stub.
    /// Separate from `init(store:)` (rather than a default argument) because the
    /// store factory is main-actor-isolated and a default-argument expression is
    /// evaluated in a nonisolated context; a `@MainActor` convenience init runs
    /// the factory on the main actor instead, keeping the call warning-free.
    convenience init() {
        self.init(store: HealthService.defaultStore())
    }

    /// Real `HKHealthStore` adapter in production; a non-prompting in-memory stub
    /// under the `-dp_uitest` launch arg so UI tests never hit the system Health
    /// permission sheet. Inert in production (`UITestSeed.isActive` is always
    /// false there) — mirrors `ReminderService.defaultCenter()`. Kept
    /// `@MainActor` (not `nonisolated`) so referencing the main-actor `isActive`
    /// and the two main-actor-isolated store inits stays warning-free.
    static func defaultStore() -> HealthWriting {
        UITestSeed.isActive ? UITestHealthStore() : HealthKitAdapter()
    }

    // MARK: - Authorization

    /// Requests read + write authorization. Returns whether it was granted;
    /// catches and logs any error, returning false rather than throwing.
    func requestAuthorization() async -> Bool {
        do {
            return try await store.requestAuthorization()
        } catch {
            logger.error("Health authorization request failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Current share (write) authorization state.
    func authorizationStatus() -> HealthAuthStatus {
        store.authorizationStatus()
    }

    // MARK: - Mutations (best-effort, serialized per event uuid)

    /// Writes a Health sample for `event` if Health is available and authorized.
    /// Find-and-relink dedup: if a sample already carries this event's
    /// `dp_event_uuid`, relink to it (no duplicate write); otherwise write fresh
    /// and stamp `event.healthKitUUID`.
    func write(_ event: ConsumptionEvent) async {
        await runSerial(event.uuid) { [weak self] in
            await self?.performWrite(event)
        }
    }

    /// Rewrites the Health sample for an edited `event`: deletes the previously
    /// linked sample (if any), then writes fresh (re-running dedup).
    func update(_ event: ConsumptionEvent) async {
        await runSerial(event.uuid) { [weak self] in
            await self?.performUpdate(event)
        }
    }

    /// Removes the Health sample for a deleted `event` and clears its cache.
    func remove(_ event: ConsumptionEvent) async {
        await runSerial(event.uuid) { [weak self] in
            await self?.performRemove(event)
        }
    }

    /// Value-based removal for a deleted event. The caller captures the event's
    /// `healthKitUUID` (device-local cache) and `uuid` BEFORE `context.delete`
    /// invalidates the `@Model`, then invokes this fire-and-forget. Deletes by the
    /// cached UUID when present, else by a `dp_event_uuid` metadata query.
    func removeSample(healthKitUUID: UUID?, eventUUID: UUID) async {
        await runSerial(eventUUID) { [weak self] in
            await self?.performRemoveSample(healthKitUUID: healthKitUUID, eventUUID: eventUUID)
        }
    }

    /// Mirrors a batch of past events (one-time enable backfill). Dedup makes it
    /// idempotent — re-running relinks existing samples instead of duplicating.
    /// Best-effort: an individual failure is swallowed and the loop continues.
    func backfill(_ events: [ConsumptionEvent]) async {
        for event in events {
            await write(event)
        }
    }

    // MARK: - Implementations

    private func performWrite(_ event: ConsumptionEvent) async {
        guard store.isHealthDataAvailable, authorizationStatus() == .authorized else { return }
        do {
            if let existing = try await store.sampleUUID(forEventUUID: event.uuid) {
                // Dedup: an earlier sample already represents this event — relink
                // the device-local cache instead of writing a duplicate.
                event.healthKitUUID = existing
                return
            }
            event.healthKitUUID = try await store.save(
                grams: event.pureAlcoholGrams,
                date: event.consumptionDate,
                eventUUID: event.uuid
            )
        } catch {
            // Best-effort: leave healthKitUUID untouched, surface only the category.
            logger.error("Health write failed: \(error.localizedDescription)")
        }
    }

    private func performUpdate(_ event: ConsumptionEvent) async {
        guard store.isHealthDataAvailable, authorizationStatus() == .authorized else { return }
        if let old = event.healthKitUUID {
            do {
                try await store.delete(uuid: old)
            } catch {
                // Stale sample may linger; the fresh write below still proceeds.
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
        guard store.isHealthDataAvailable, authorizationStatus() == .authorized else { return }
        do {
            // Prefer the cached UUID; fall back to a metadata query if it is nil
            // (e.g. a sample written on this device but not yet cached).
            var target = healthKitUUID
            if target == nil {
                target = try await store.sampleUUID(forEventUUID: eventUUID)
            }
            if let target {
                try await store.delete(uuid: target)
            }
        } catch {
            // Best-effort: a failed delete leaves a harmless orphan sample.
            logger.error("Health remove failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Per-event serialization

    /// Chains `work` after any in-flight op for `id`, so operations on the same
    /// event uuid run strictly one-at-a-time (no edit→delete race). Cleans up the
    /// tail entry once it is the last op, keeping the map bounded.
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
