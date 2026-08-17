import Foundation

final class UITestHealthStore: HealthWriting, @unchecked Sendable {
    nonisolated static let sampleCountKey = "dp_uitest_health_sample_count"

    private var samplesByEvent: [UUID: UUID] = [:] {
        didSet { UserDefaults.standard.set(samplesByEvent.count, forKey: Self.sampleCountKey) }
    }

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
