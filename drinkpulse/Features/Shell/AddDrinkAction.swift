import SwiftUI

/// Opens the Add Drink sheet that the shell owns. Screens that log drinks call it from their
/// own `+` toolbar item (`AddDrinkToolbarItem`).
struct AddDrinkAction {
    var handler: @MainActor () -> Void = {}

    @MainActor func callAsFunction() {
        handler()
    }
}

extension EnvironmentValues {
    @Entry var addDrink = AddDrinkAction()
}
