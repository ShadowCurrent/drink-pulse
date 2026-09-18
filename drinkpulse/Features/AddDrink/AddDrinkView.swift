import SwiftUI
import SwiftData

struct AddDrinkView: View {
    @Environment(\.dismiss) private var dismissSheet

    var body: some View {
        NavigationStack {
            DrinkTypeGridView(dismissSheet: dismissSheet)
        }
    }
}

#Preview {
    AddDrinkView()
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}
