import Foundation
import HealthKit

final class HealthKitAdapter: HealthWriting, @unchecked Sendable {
    private let store = HKHealthStore()
    private let alcoholType = HKQuantityType(.numberOfAlcoholicBeverages)

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
        try await store.deleteObjects(
            of: alcoholType,
            predicate: HKQuery.predicateForObject(with: uuid)
        )
    }
}
