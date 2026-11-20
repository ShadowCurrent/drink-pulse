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

    /// Reads 30 years before now while no date of birth is stored; reading never writes.
    var dateOfBirthBinding: Binding<Date> {
        Binding(
            get: { self.dateOfBirth ?? Self.defaultDateOfBirth },
            set: { newValue in
                guard self.dateOfBirth != newValue else { return }
                self.dateOfBirth = newValue
                self.touch()
            }
        )
    }

    private static var defaultDateOfBirth: Date {
        Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now
    }
}
