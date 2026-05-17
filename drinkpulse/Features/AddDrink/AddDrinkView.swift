import SwiftUI
import SwiftData

extension EnvironmentValues {
    @Entry var dismissSheet: (() -> Void)? = nil
}

struct AddDrinkView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DrinkTypeGridView()
        }
        .environment(\.dismissSheet, { dismiss() })
    }
}

#Preview {
    AddDrinkView()
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}
