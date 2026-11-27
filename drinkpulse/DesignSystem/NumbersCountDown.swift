import SwiftUI

extension EnvironmentValues {
    /// Direction of the numeric content transition (plan 0046, D0046-8): `true` while the user
    /// navigates back in time, so numbers roll the way the period moved.
    @Entry var numbersCountDown: Bool = false
}
