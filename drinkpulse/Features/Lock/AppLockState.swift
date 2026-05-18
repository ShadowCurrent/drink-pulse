import Observation

@Observable
@MainActor
final class AppLockState {
    var isLocked = false

    func lock() {
        isLocked = true
    }

    func unlock() {
        isLocked = false
    }
}
