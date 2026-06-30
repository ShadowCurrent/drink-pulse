import SwiftUI
import SwiftData

struct RootShellView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showAddDrink = false
    @AppStorage(AppStorageKeys.onboardingDone) private var onboardingDone = false
    @AppStorage(AppStorageKeys.pendingAddDrink) private var pendingAddDrink = false
    /// Mirrors the in-memory Health sample count under `-dp_uitest`, so the W5
    /// regression UI test can assert a sample was actually written on add (XCUITest
    /// can only observe on-screen state). Inert in production — the probe view is
    /// only added when `UITestSeed.isActive`.
    @AppStorage(UITestHealthStore.sampleCountKey) private var healthSampleCount = 0
    @Environment(\.scenePhase) private var scenePhase
    @Query private var profiles: [UserProfile]

    private let reminderService = ReminderService()

    var body: some View {
        ZStack {
            Color.dpAccent.opacity(0.04).ignoresSafeArea()
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
                    Label(String(localized: "tab.home"), systemImage: "house")
                        .environment(\.symbolVariants, selectedTab == .home ? .fill : .none)
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
                    Label(String(localized: "tab.insights"), systemImage: "chart.bar")
                        .environment(\.symbolVariants, selectedTab == .insights ? .fill : .none)
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
                    Label(String(localized: "tab.history"), systemImage: "clock")
                        .environment(\.symbolVariants, selectedTab == .history ? .fill : .none)
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
                    Label(String(localized: "tab.settings"), systemImage: "gearshape")
                        .environment(\.symbolVariants, selectedTab == .settings ? .fill : .none)
                }
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: showAddDrink) { _, new in new }
            .sheet(isPresented: $showAddDrink) {
                AddDrinkView()
            }
            .overlay(alignment: .topLeading) {
                // UI-test-only probe (W5 Health-write regression). Surfaces the live
                // Health sample count so XCUITest can assert a sample was written on
                // add. Gated on -dp_uitest; never added in production.
                if UITestSeed.isActive {
                    Text(verbatim: "\(healthSampleCount)")
                        .font(.system(size: 1))
                        .foregroundStyle(.clear)
                        .accessibilityIdentifier("dp_health_sample_count")
                }
            }
            .onChange(of: profiles.isEmpty) { _, isEmpty in
                if isEmpty { onboardingDone = false }
            }
            .onAppear { openAddDrinkIfPending() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await reminderService.scheduleIfEnabled() } }
            }
            .task {
                // A reminder tapped while the app is already running posts this
                // event; present Add Drink and clear the persisted flag.
                for await _ in NotificationCenter.default.notifications(
                    named: NotificationActionHandler.didTapReminder
                ) {
                    pendingAddDrink = false
                    showAddDrink = true
                }
            }
        }
    }

    /// Cold-launch path: a reminder tapped while the app was killed set the
    /// persisted flag; consume it on appear so Add Drink opens once.
    private func openAddDrinkIfPending() {
        guard pendingAddDrink else { return }
        pendingAddDrink = false
        showAddDrink = true
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
