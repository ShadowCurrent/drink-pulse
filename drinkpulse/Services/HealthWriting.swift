import Foundation

enum HealthAuthStatus: Sendable {
    case notDetermined
    case denied
    case authorized
}

enum HealthSampleMetadata {
    static let eventUUIDKey = "dp_event_uuid"
}

protocol HealthWriting: Sendable {
    var isHealthDataAvailable: Bool { get }

    func requestAuthorization() async throws -> Bool

    func authorizationStatus() -> HealthAuthStatus

    func save(grams: Double, date: Date, eventUUID: UUID) async throws -> UUID

    func sampleUUID(forEventUUID eventUUID: UUID) async throws -> UUID?

    func delete(uuid: UUID) async throws
}
