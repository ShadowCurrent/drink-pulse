import SwiftUI
import SwiftData

struct DashboardView: View {
    @State private var showAddDrink = false

    var body: some View {
        Text(String(localized: "Coming soon"))
            .foregroundStyle(.secondary)
            .navigationTitle(String(localized: "Home"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Add drink"), systemImage: "plus") {
                        showAddDrink = true
                    }
                    .accessibilityLabel(String(localized: "Add drink"))
                }
            }
            .sheet(isPresented: $showAddDrink) {
                AddDrinkView()
            }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(
        for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self, GuidelineProfile.self],
        inMemory: true
    )
}
