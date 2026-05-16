import SwiftUI

struct DashboardView: View {
    var body: some View {
        Text(String(localized: "dashboard.placeholder"))
            .foregroundStyle(.secondary)
            .navigationTitle(String(localized: "tab.home"))
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
