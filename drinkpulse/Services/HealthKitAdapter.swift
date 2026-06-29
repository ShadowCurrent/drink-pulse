import Foundation
import HealthKit

/// Thin real `HealthWriting` conformance over `HKHealthStore` (plan-0036).
/// Framework glue — excluded from unit coverage (ADR-0008); the logic that uses
/// it (`HealthService`) is tested through the `HealthWriting` fake.
///
/// HealthKit has **no grams-based alcohol type**; the writable "drinks" type is
/// `numberOfAlcoholicBeverages` (unit: count). Apple defines one beverage as a US
/// standard drink = **14 g** pure alcohol, so we write `grams / 14.0` as a count.
/// This mapping is FIXED (independent of the user's display unit / guideline) so
/// Health values never shift when the user toggles units — same posture as
/// calories/BAC using physical 0.789. Each sample carries `metadata[dp_event_uuid]`
/// so we find-and-relink our own prior sample instead of duplicating (ADR-0011).
final class HealthKitAdapter: HealthWriting, @unchecked Sendable {
    private let store = HKHealthStore()
    private let alcoholType = HKQuantityType(.numberOfAlcoholicBeverages)

    /// Apple's fixed definition of one `numberOfAlcoholicBeverages` unit (US
    /// standard drink). NOT the user's guideline std-drink size — see class doc.
    private let gramsPerStandardDrink = 14.0

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws -> Bool {
        try await store.requestAuthorization(toShare: [alcoholType], read: [alcoholType])
        return true
    }

    func authorizationStatus() -> HealthAuthStatus {
        switch store.authorizationStatus(for: alcoholType) {
        case .sharingAuthorized: .authorized
        case .sharingDenied:     .denied
        default:                 .notDetermined
        }
    }

    func save(grams: Double, date: Date, eventUUID: UUID) async throws -> UUID {
        // HealthKit type is a count of US standard drinks (14 g each), not grams.
        let quantity = HKQuantity(unit: .count(), doubleValue: grams / gramsPerStandardDrink)
        let sample = HKQuantitySample(
            type: alcoholType,
            quantity: quantity,
            start: date,
            end: date,
            metadata: [HealthSampleMetadata.eventUUIDKey: eventUUID.uuidString]
        )
        try await store.save(sample)
        return sample.uuid
    }

    func sampleUUID(forEventUUID eventUUID: UUID) async throws -> UUID? {
        let metadataPredicate = HKQuery.predicateForObjects(
            withMetadataKey: HealthSampleMetadata.eventUUIDKey,
            operatorType: .equalTo,
            value: eventUUID.uuidString
        )
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: alcoholType, predicate: metadataPredicate)],
            sortDescriptors: [],
            limit: 1
        )
        let samples = try await descriptor.result(for: store)
        return samples.first?.uuid
    }

    func delete(uuid: UUID) async throws {
        // Delete only the matching object; a non-existent UUID is a silent no-op.
        try await store.deleteObjects(
            of: alcoholType,
            predicate: HKQuery.predicateForObject(with: uuid)
        )
    }
}
