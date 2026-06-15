import SwiftUI

/// Appearance section rows for use inside a List Section in SettingsView.
struct AppearanceRows: View {
    @AppStorage(AppStorageKeys.theme) private var theme: DPTheme = .ember
    @AppStorage(AppStorageKeys.colorScheme) private var colorSchemeRaw: String = "system"

    var body: some View {
        SettingsRow(String(localized: "settings.appearance.theme")) {
            HStack(spacing: 10) {
                ForEach(DPTheme.allCases, id: \.self) { option in
                    Button { theme = option } label: {
                        ThemeSwatch(option: option, isSelected: theme == option)
                    }
                    .buttonStyle(.plain)
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
                    // Dark scrim disc behind the glyph so the white checkmark
                    // keeps ≥4.5:1 contrast on light gradient ends (e.g. Ember).
                    Circle()
                        .fill(.black.opacity(0.45))
                        .frame(width: 18, height: 18)
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
