import SwiftUI
import SwiftData

struct RootShellView: View {
    @State private var tab: AppTab = .home
    @State private var showAddDrink = false

    var body: some View {
        activeScreen
            .safeAreaInset(edge: .bottom, spacing: 0) {
                DPBottomBar(
                    selected: tab,
                    onSelect: { tab = $0 },
                    onAddDrink: { showAddDrink = true }
                )
            }
            .sheet(isPresented: $showAddDrink) {
                AddDrinkView()
            }
    }

    @ViewBuilder
    private var activeScreen: some View {
        switch tab {
        case .home:     NavigationStack { DashboardView() }
        case .insights: NavigationStack { InsightsView() }
        case .history:  NavigationStack { HistoryView() }
        case .settings: NavigationStack { SettingsView() }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(UserProfile.preview)
    return RootShellView().modelContainer(container)
}
