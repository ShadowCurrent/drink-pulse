import SwiftUI
import SwiftData

@MainActor
private func insightsContainer(withEvents: Bool) -> ModelContainer {
    let container = try! ModelContainer(
        for: DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    container.mainContext.insert(UserProfile.preview)
    if withEvents {
        for event in InsightsDataGenerator.previewEvents(days: 90) {
            container.mainContext.insert(event)
        }
    }
    return container
}

#Preview("Insights") {
    NavigationStack { InsightsView() }
        .modelContainer(insightsContainer(withEvents: true))
}

#Preview("Insights · Dark") {
    NavigationStack { InsightsView() }
        .modelContainer(insightsContainer(withEvents: true))
        .preferredColorScheme(.dark)
}

#Preview("Insights · AX5") {
    NavigationStack { InsightsView() }
        .modelContainer(insightsContainer(withEvents: true))
        .dynamicTypeSize(.accessibility5)
}

#Preview("Insights · Empty") {
    NavigationStack { InsightsView() }
        .modelContainer(insightsContainer(withEvents: false))
}
