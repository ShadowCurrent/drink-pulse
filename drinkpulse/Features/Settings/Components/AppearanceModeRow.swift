import SwiftUI

struct AppearanceModeRow: View {
    @AppStorage(AppStorageKeys.colorScheme) private var colorSchemeRaw: String = "system"

    var body: some View {
        SettingsRow(String(localized: "settings.appearance.mode")) {
            SettingsMenuPicker(
                title: String(localized: "settings.appearance.mode"),
                selectionLabel: selectionLabel,
                selection: $colorSchemeRaw
            ) {
                Text(String(localized: "settings.appearance.mode.system")).tag("system")
                Text(String(localized: "settings.appearance.mode.light")).tag("light")
                Text(String(localized: "settings.appearance.mode.dark")).tag("dark")
            }
        }
    }

    private var selectionLabel: String {
        switch colorSchemeRaw {
        case "light": String(localized: "settings.appearance.mode.light")
        case "dark": String(localized: "settings.appearance.mode.dark")
        default: String(localized: "settings.appearance.mode.system")
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
