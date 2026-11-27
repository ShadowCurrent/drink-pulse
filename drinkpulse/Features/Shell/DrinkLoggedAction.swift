import SwiftUI

/// Tells the shell that the user logged a drink, so it can play the logging haptic.
///
/// Only the two user log paths call it (Add Drink save, History duplicate). Imports, the
/// Health backfill and UI-test seeding insert events without it, so they play no haptic.
struct DrinkLoggedAction {
    var handler: @MainActor (ConsumptionEvent) -> Void = { _ in }

    @MainActor func callAsFunction(_ event: ConsumptionEvent) {
        handler(event)
    }
}

extension EnvironmentValues {
    @Entry var drinkLogged = DrinkLoggedAction()
}
