import Foundation

/// Authorization state for the app's Health integration, as the app needs to
/// reason about it (HealthKit's own enum is framework-coupled and, for privacy,
/// never reveals read status — this collapses to what the UI shows).
enum HealthAuthStatus: Sendable {
    case notDetermined
    case denied
    case authorized
}

/// Stable metadata used to identify the HKSamples this app wrote.
enum HealthSampleMetadata {
    /// Durable, portable dedup key (ADR-0011): the `ConsumptionEvent.uuid` string.
    /// Unlike an HKSample UUID, this survives reinstall (it is in our backup) and is
    /// identical across devices, so a write/backfill can find-and-relink instead of
    /// duplicating. Stored in each sample's `metadata`.
    static let eventUUIDKey = "dp_event_uuid"
}

/// Narrow abstraction over the slice of `HKHealthStore` the app uses, so
/// `HealthService` is unit-testable without HealthKit (no real authorization
/// prompt, no real samples). Scope is **read + write**: write mirrors a logged
/// drink as a `dietaryAlcohol` sample; read is used only to find our own prior
/// sample by `dp_event_uuid` for dedup (ADR-0011).
///
/// The real conformance (`HealthKitAdapter`) is a thin framework adapter —
/// excluded from unit coverage as framework glue (ADR-0008). Tests inject a fake.
protocol HealthWriting: Sendable {
    /// Whether HealthKit is available on this device (false on, e.g., iPad without
    /// Health). Callers must no-op when false.
    var isHealthDataAvailable: Bool { get }

    /// Requests share (write) + read authorization for `dietaryAlcohol`. Returns
    /// whether the request completed (NOT whether granted — HealthKit hides read
    /// grants; use `authorizationStatus()` for the write/share state).
    func requestAuthorization() async throws -> Bool

    /// Current share (write) authorization state for `dietaryAlcohol`.
    func authorizationStatus() -> HealthAuthStatus

    /// Writes a `dietaryAlcohol` sample of `grams` at `date`, stamped with
    /// `metadata[dp_event_uuid] = eventUUID`. Returns the new sample's HK UUID.
    func save(grams: Double, date: Date, eventUUID: UUID) async throws -> UUID

    /// The HK UUID of an existing sample whose `dp_event_uuid` equals `eventUUID`,
    /// or nil if none. Used for find-and-relink dedup on write/backfill.
    func sampleUUID(forEventUUID eventUUID: UUID) async throws -> UUID?

    /// Deletes the sample with the given HK UUID (no-op if it no longer exists).
    func delete(uuid: UUID) async throws
}
