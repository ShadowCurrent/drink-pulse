import SwiftUI
import SwiftData

struct InsightsView: View {
    @State private var vm = InsightsViewModel()
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \ConsumptionEvent.timestamp, order: .reverse)
    private var allEvents: [ConsumptionEvent]
    @Query private var profiles: [UserProfile]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                InsightsScopeNavigator(vm: vm)
                InsightsHeroCard(vm: vm)
                HealthMetricsCard(vm: vm)
                WeekdayBarChart(bars: vm.weekdayAverages)
                GuidelineComparisonCard(comparisons: vm.guidelineComparisons,
                                        label: vm.comparisonLabel)
            }
            .padding()
        }
        .navigationTitle(String(localized: "tab.insights"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: allEvents, initial: true) { vm.events = allEvents }
        .onChange(of: profiles, initial: true) { vm.profile = profiles.first }
        .onChange(of: scenePhase) { if scenePhase == .active { vm.now = .now } }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(UserProfile.preview)
    for event in InsightsDataGenerator.previewEvents(days: 90) {
        container.mainContext.insert(event)
    }
    return NavigationStack { InsightsView() }
        .modelContainer(container)
}
