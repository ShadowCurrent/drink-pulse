import Foundation
import os
import UserNotifications
@testable import drinkpulse

/// Test double whose first `add` call suspends until `release()` is called.
///
/// Every later `add` completes without suspending, so a test can hold one
/// schedule inside `add` while another schedule runs to completion. Adds apply
/// the way the real center does (a request with an existing identifier replaces
/// the old one) and every add and remove lands in an ordered `operationLog`.
/// All mutable state lives behind one `OSAllocatedUnfairLock`, so the service
/// and the test can touch it from different threads without a data race.
final class SlowNotificationCenter: NotificationScheduling, @unchecked Sendable {
    enum Operation: Equatable, Sendable {
        case add(String)
        case remove([String])
    }

    private struct State: Sendable {
        var pending: [String] = []
        var addCallCount = 0
        var addEntered = false
        var released = false
        var continuation: CheckedContinuation<Void, Never>?
        var log: [Operation] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    /// True once the gated first `add` call has been entered.
    var addEntered: Bool { state.withLock { $0.addEntered } }

    /// Copy of the ordered add and remove entries.
    var operationLog: [Operation] { state.withLock { $0.log } }

    /// Lets the gated `add` continue. Safe to call before or after `add` was entered, and more than once.
    func release() {
        let waiting = state.withLock { state -> CheckedContinuation<Void, Never>? in
            state.released = true
            let continuation = state.continuation
            state.continuation = nil
            return continuation
        }
        waiting?.resume()
    }

    /// Polls with `Task.yield` until the gated `add` is entered or the deadline passes. Never sleeps.
    func waitUntilAddEntered(timeout: Duration = .seconds(2)) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while !addEntered {
            if ContinuousClock.now >= deadline { return false }
            await Task.yield()
        }
        return true
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }

    func add(_ request: UNNotificationRequest) async throws {
        let identifier = request.identifier
        let isGated = state.withLock { state -> Bool in
            state.addCallCount += 1
            guard state.addCallCount == 1 else { return false }
            state.addEntered = true
            return true
        }
        if isGated {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                // Store-or-resume is decided inside one locked section, so a release that
                // arrived first is never lost and the continuation is resumed exactly once.
                let resumeNow = state.withLock { state -> Bool in
                    if state.released { return true }
                    state.continuation = continuation
                    return false
                }
                if resumeNow { continuation.resume() }
            }
        }
        state.withLock { state in
            state.pending.removeAll { $0 == identifier }
            state.pending.append(identifier)
            state.log.append(.add(identifier))
        }
    }

    func pendingRequestIdentifiers() async -> [String] {
        state.withLock { $0.pending }
    }

    func removePendingRequests(withIdentifiers ids: [String]) {
        state.withLock { state in
            state.pending.removeAll { ids.contains($0) }
            state.log.append(.remove(ids))
        }
    }
}
