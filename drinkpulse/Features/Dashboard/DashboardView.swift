import SwiftUI
import SwiftData

struct DashboardView: View {
    @State private var showAddDrink = false

    var body: some View {
        Text(String(localized: "dashboard.placeholder"))
            .foregroundStyle(.secondary)
            .navigationTitle(String(localized: "tab.home"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "addDrink.title"), systemImage: "plus") {
                        showAddDrink = true
                    }
                    .accessibilityLabel(String(localized: "addDrink.title"))
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
