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
                PeriodPicker(period: $vm.period)
                AlcoholAreaChart(data: vm.seriesData, period: vm.period)
                WeekdayBarChart(bars: vm.weekdayAverages)
                ActivityHeatmap(cells: vm.heatmapCells)
                HealthMetricsCard(vm: vm)
                GuidelineComparisonCard(
                    comparisons: vm.guidelineComparisons,
                    weeklyGrams: vm.sevenDayGrams
                )
            }
            .padding()
        }
        .navigationTitle(String(localized: "tab.insights"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: allEvents, initial: true) {
            vm.events = allEvents
        }
        .onChange(of: profiles, initial: true) {
            vm.profile = profiles.first
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active { vm.now = .now }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self,
        configurations: config
    )
    let ctx = container.mainContext
    ctx.insert(UserProfile.preview)
    let cal = Calendar.current
    let now = Date.now
    for i in 0..<21 {
        if let ts = cal.date(byAdding: .day, value: -i, to: now) {
            let e = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: 0.05,
                                     name: "Beer", category: .beer, icon: "🍺")
            ctx.insert(e)
        }
    }
    return NavigationStack { InsightsView() }
        .modelContainer(container)
}
