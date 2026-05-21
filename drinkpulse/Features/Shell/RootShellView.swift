import SwiftUI
import SwiftData

struct RootShellView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showAddDrink = false
    @Environment(\.dpTheme) private var theme

    var body: some View {
        ZStack {
            theme.primary.opacity(0.04).ignoresSafeArea()
            TabView(selection: $selectedTab) {
                Tab(value: AppTab.home) {
                    NavigationStack {
                        DashboardView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    AddDrinkButton { showAddDrink = true }
                                }
                            }
                    }
                } label: {
                    tabLabel("tab.home",
                             icon: "house",
                             filledIcon: "house.fill",
                             tab: .home)
                }

                Tab(value: AppTab.insights) {
                    NavigationStack {
                        InsightsView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    AddDrinkButton { showAddDrink = true }
                                }
                            }
                    }
                } label: {
                    tabLabel("tab.insights",
                             icon: "chart.bar",
                             filledIcon: "chart.bar.fill",
                             tab: .insights)
                }

                Tab(value: AppTab.history) {
                    NavigationStack {
                        HistoryView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    AddDrinkButton { showAddDrink = true }
                                }
                            }
                    }
                } label: {
                    tabLabel("tab.history",
                             icon: "clock",
                             filledIcon: "clock.fill",
                             tab: .history)
                }

                Tab(value: AppTab.settings) {
                    NavigationStack {
                        SettingsView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    AddDrinkButton { showAddDrink = true }
                                }
                            }
                    }
                } label: {
                    tabLabel("tab.settings",
                             icon: "gearshape",
                             filledIcon: "gearshape.fill",
                             tab: .settings)
                }
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: showAddDrink) { _, new in new }
            .sheet(isPresented: $showAddDrink) {
                AddDrinkView()
            }
        }
    }

    private func tabLabel(
        _ titleKey: String,
        icon: String,
        filledIcon: String,
        tab: AppTab
    ) -> some View {
        let isSelected = selectedTab == tab
        return Label {
            Text(String(localized: String.LocalizationValue(titleKey)))
        } icon: {
            Image(systemName: isSelected ? filledIcon : icon)
                .contentTransition(.symbolEffect(.replace))
                .animation(.spring(duration: 0.3), value: isSelected)
        }
        .environment(\.symbolVariants, .none)
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
