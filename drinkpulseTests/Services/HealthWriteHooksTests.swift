import Foundation
import SwiftData
import Testing
@testable import drinkpulse

/// Unit coverage for `HealthWriteHooks` (plan-0036, W5) — the bridge from the
/// in-app Add/Edit/Delete sites to the optional `HealthService`.
///
/// The W5 regression these pin: the Add flow must actually invoke the service
/// (and stamp the event's device-local `healthKitUUID`) when write-back is
/// enabled, and must no-op cleanly when disabled or when no service is wired.
/// `HealthService.write` itself is covered by `HealthServiceTests`; here we prove
/// the *hook* reaches it. The hooks now return their fire-and-forget `Task` so the
/// test can await the wiring deterministically.
///
/// `.serialized`: every test drives the process-global `dp_health_write_enabled`
/// flag, so they must not run in parallel (Swift Testing's default) or they would
/// clobber each other's gate state.
@MainActor
@Suite(.serialized)
struct HealthWriteHooksTests {

    /// Drives the `dp_health_write_enabled` gate around `body`, restoring the prior
    /// value afterwards so tests don't leak the flag into each other.
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

    /// Returns a retained in-memory container. The caller must keep this alive for
    /// the test: a `ModelContext` whose container deallocates dangles and crashes
    /// on use, so we never hand back a bare context from a dropped container.
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

            // Rewrites the sample: deletes the old one, then writes fresh.
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
