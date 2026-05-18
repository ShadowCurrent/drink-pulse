import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppLockState.self) private var lockState
    @Environment(\.scenePhase) private var scenePhase
    @Query private var profiles: [UserProfile]

    private var appLockEnabled: Bool { profiles.first?.appLockEnabled ?? false }

    var body: some View {
        ZStack {
            TabView {
                NavigationStack {
                    DashboardView()
                }
                .tabItem { Label(String(localized: "tab.home"), systemImage: "house.fill") }

                NavigationStack {
                    HistoryView()
                }
                .tabItem { Label(String(localized: "tab.history"), systemImage: "calendar") }

                NavigationStack {
                    SettingsView()
                }
                .tabItem { Label(String(localized: "tab.settings"), systemImage: "gear") }
            }

            if lockState.isLocked {
                LockScreenView(onUnlock: { lockState.unlock() })
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: lockState.isLocked)
        .onChange(of: scenePhase) { _, new in
            if new == .background && appLockEnabled {
                lockState.lock()
            }
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
    return ContentView()
        .modelContainer(container)
        .environment(AppLockState())
}
