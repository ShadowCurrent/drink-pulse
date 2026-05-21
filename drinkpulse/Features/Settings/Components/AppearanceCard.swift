import SwiftUI

/// Appearance section rows for use inside a List Section in SettingsView.
struct AppearanceRows: View {
    @AppStorage("dp_theme") private var theme: DPTheme = .ember
    @AppStorage("dp_color_scheme") private var colorSchemeRaw: String = "system"

    var body: some View {
        SettingsRow(String(localized: "settings.appearance.theme")) {
            HStack(spacing: 10) {
                ForEach(DPTheme.allCases, id: \.self) { option in
                    ThemeSwatch(option: option, isSelected: theme == option)
                        .onTapGesture { theme = option }
                }
            }
        }
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

private struct ThemeSwatch: View {
    let option: DPTheme
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(option.gradient)
            .frame(width: 28, height: 28)
            .overlay {
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2.5)
                        .padding(2)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .accessibilityLabel(option.displayName)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    List {
        Section("APPEARANCE") {
            AppearanceRows()
        }
    }
    .listStyle(.insetGrouped)
}
