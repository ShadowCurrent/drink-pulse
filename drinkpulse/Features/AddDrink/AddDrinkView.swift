import SwiftUI
import SwiftData

struct AddDrinkView: View {
    @Environment(\.dismiss) private var dismissSheet

    var body: some View {
        NavigationStack {
            DrinkTypeListView(dismissSheet: dismissSheet)
        }
        // `.automatic` hides the grabber on a large-only sheet; show it, as Edit Drink does,
        // so swipe-to-dismiss is discoverable on both steps.
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    AddDrinkView()
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}
