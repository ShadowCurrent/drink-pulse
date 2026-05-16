import SwiftUI

struct SettingsView: View {
    var body: some View {
        Text(String(localized: "settings.placeholder"))
            .foregroundStyle(.secondary)
            .navigationTitle(String(localized: "tab.settings"))
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
