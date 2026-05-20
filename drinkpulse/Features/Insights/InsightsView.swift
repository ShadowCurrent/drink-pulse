import SwiftUI

// TODO: Populate with charts and metrics in plan-0012.
struct InsightsView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "insights.comingSoon.title"),
            systemImage: "chart.bar.fill",
            description: Text(String(localized: "insights.comingSoon.description"))
        )
        .navigationTitle(String(localized: "tab.insights"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { InsightsView() }
}
