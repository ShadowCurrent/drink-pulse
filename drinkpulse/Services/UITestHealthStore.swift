import Foundation

/// Launch-argument-gated stand-in for `HealthKitAdapter`, used only when
/// `-dp_uitest` is active (see `UITestSeed`). It auto-grants authorization and
/// records writes/deletes in memory, so UI tests can exercise the Health toggle
/// and write wiring **without** the real system permission sheet and without
/// touching the device Health store.
///
/// Inert in production: `HealthService.defaultStore()` only selects it when
/// `UITestSeed.isActive` is true, impossible outside a UI-test launch. Carries no
/// PII and performs no real platform side effects.
final class UITestHealthStore: HealthWriting, @unchecked Sendable {
    /// HK UUID written per event uuid (mirrors the find-and-relink contract).
    private var samplesByEvent: [UUID: UUID] = [:]

    var isHealthDataAvailable: Bool { true }

    func requestAuthorization() async throws -> Bool { true }

    func authorizationStatus() -> HealthAuthStatus { .authorized }

    func save(grams: Double, date: Date, eventUUID: UUID) async throws -> UUID {
        let sampleUUID = UUID()
        samplesByEvent[eventUUID] = sampleUUID
        return sampleUUID
    }

    func sampleUUID(forEventUUID eventUUID: UUID) async throws -> UUID? {
        samplesByEvent[eventUUID]
    }

    func delete(uuid: UUID) async throws {
        samplesByEvent = samplesByEvent.filter { $0.value != uuid }
    }
}
