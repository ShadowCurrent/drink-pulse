import SwiftUI

/// Bindings for Settings controls that keep the LWW contract: a write that does not change
/// the value leaves `modifiedDate` alone (a menu re-selecting the current value is a no-op).
@MainActor
extension UserProfile {
    func touchingBinding<T: Equatable>(_ keyPath: ReferenceWritableKeyPath<UserProfile, T>) -> Binding<T> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { newValue in
                guard self[keyPath: keyPath] != newValue else { return }
                self[keyPath: keyPath] = newValue
                self.touch()
            }
        )
    }
}
