import SwiftUI

struct SettingsView: View {
    var body: some View {
        Text(String(localized: "settings.placeholder"))
            .foregroundStyle(.secondary)
            .navigationTitle(String(localized: "tab.settings"))
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
