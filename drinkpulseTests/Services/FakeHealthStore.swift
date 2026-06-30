import Foundation
@testable import drinkpulse

/// Configurable `HealthWriting` fake that records calls, so `HealthService` can
/// be tested without HealthKit (no real prompt, no real samples). Separate from
/// the production `UITestHealthStore` stub. `@unchecked Sendable`: all access
/// happens on the MainActor (the tests and the service are `@MainActor`).
final class FakeHealthStore: HealthWriting, @unchecked Sendable {
    var available = true
    var status: HealthAuthStatus = .authorized
    var authResult = true
    var authError: Error?
    /// When true, a successful `requestAuthorization()` flips `status` to
    /// `.authorized` — models a real device where a fresh process reports a stale
    /// `.notDetermined` until the service re-requests (self-heal path).
    var authorizesOnRequest = false
    var throwOnSave = false
    var throwOnDelete = false
    var throwOnQuery = false

    /// event uuid -> the HK sample uuid currently representing it.
    private(set) var samplesByEvent: [UUID: UUID] = [:]

    private(set) var saveCount = 0
    private(set) var deleteCount = 0
    private(set) var queryCount = 0
    private(set) var savedGrams: [Double] = []
    private(set) var deletedUUIDs: [UUID] = []

    init(seed: [UUID: UUID] = [:]) { samplesByEvent = seed }

    var isHealthDataAvailable: Bool { available }

    func requestAuthorization() async throws -> Bool {
        if let authError { throw authError }
        if authorizesOnRequest { status = .authorized }
        return authResult
    }

    func authorizationStatus() -> HealthAuthStatus { status }

    func save(grams: Double, date: Date, eventUUID: UUID) async throws -> UUID {
        saveCount += 1
        if throwOnSave { throw FakeHealthError.save }
        let id = UUID()
        samplesByEvent[eventUUID] = id
        savedGrams.append(grams)
        return id
    }

    func sampleUUID(forEventUUID eventUUID: UUID) async throws -> UUID? {
        queryCount += 1
        if throwOnQuery { throw FakeHealthError.query }
        return samplesByEvent[eventUUID]
    }

    func delete(uuid: UUID) async throws {
        deleteCount += 1
        if throwOnDelete { throw FakeHealthError.delete }
        deletedUUIDs.append(uuid)
        samplesByEvent = samplesByEvent.filter { $0.value != uuid }
    }
}

enum FakeHealthError: Error { case save, delete, query, auth }
