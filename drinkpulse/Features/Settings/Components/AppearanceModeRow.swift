import SwiftUI

/// Light/Dark/System mode row. Lives inside the multi-row PREFERENCES card in
/// SettingsView — never in a single-row card, because an iOS 26 `.menu` morph
/// inside a single-row `dpGlassCard` collapses the whole card into the bubble.
struct AppearanceModeRow: View {
    @AppStorage(AppStorageKeys.colorScheme) private var colorSchemeRaw: String = "system"

    var body: some View {
        SettingsRow(String(localized: "settings.appearance.mode")) {
            Picker(String(localized: "settings.appearance.mode"), selection: $colorSchemeRaw) {
                Text(String(localized: "settings.appearance.mode.system")).tag("system")
                Text(String(localized: "settings.appearance.mode.light")).tag("light")
                Text(String(localized: "settings.appearance.mode.dark")).tag("dark")
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }
}

#Preview {
    ScrollView {
        SettingsSection("settings.section.preferences") {
            AppearanceModeRow()
            Divider()
            SettingsRow("Volume unit") { Text("ml").foregroundStyle(.secondary) }
        }
        .padding()
    }
}
