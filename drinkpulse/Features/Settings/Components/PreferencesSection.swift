import SwiftUI
import SwiftData

/// Preferences: appearance, volume unit, alcohol unit, ABV precision, currency. Plain `Picker`s
/// take the menu style a `Form` gives them by default (SwiftUI docs, `Picker`).
struct PreferencesSection: View {
    @Bindable var profile: UserProfile
    @AppStorage(AppStorageKeys.colorScheme) private var colorSchemeRaw: String = "system"

    var body: some View {
        Section {
            Picker(String(localized: "settings.appearance.mode"), selection: $colorSchemeRaw) {
                Text(String(localized: "settings.appearance.mode.system")).tag("system")
                Text(String(localized: "settings.appearance.mode.light")).tag("light")
                Text(String(localized: "settings.appearance.mode.dark")).tag("dark")
            }
            Picker(String(localized: "settings.volumeUnit"), selection: profile.touchingBinding(\.unitSystem)) {
                Text(String(localized: "settings.volumeUnit.ml")).tag(UnitSystem.metric)
                Text(String(localized: "settings.volumeUnit.usOz")).tag(UnitSystem.usCustomary)
                Text(String(localized: "settings.volumeUnit.imperialOz")).tag(UnitSystem.imperial)
            }
            Picker(String(localized: "settings.alcoholUnit"), selection: profile.touchingBinding(\.alcoholUnit)) {
                ForEach(AlcoholUnit.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }
            Picker(
                String(localized: "settings.abvPrecision"),
                selection: profile.touchingBinding(\.abvPrecisionPermille)
            ) {
                Text(Self.abvPrecisionLabel(permille: 5)).tag(5)
                Text(Self.abvPrecisionLabel(permille: 1)).tag(1)
            }
            Picker(String(localized: "settings.currency"), selection: profile.touchingBinding(\.currency)) {
                ForEach(CurrencyCatalog.common) { option in
                    Text("\(option.code) · \(option.symbol)").tag(option.code)
                }
            }
        } header: {
            Text(String(localized: "settings.section.preferences"))
        }
        .settingsPickerStyle()
    }

    private static func abvPrecisionLabel(permille: Int) -> String {
        let pct = (Double(permille) / 1000.0).formatted(.percent.precision(.fractionLength(1)))
        let key = permille == 5 ? "settings.abvPrecision.coarse" : "settings.abvPrecision.fine"
        return String(format: String(localized: String.LocalizationValue(key)), pct)
    }
}

/// Menu pickers at standard sizes; pushed option lists at accessibility sizes, where the menu
/// button clips a wrapped value (brief C016, plan 0043 D0043-4). Same pattern as the Add / Edit
/// Drink wheels (plan 0040). SwiftUI docs: `NavigationLinkPickerStyle` "when … your design is
/// better expressed by pushing onto a stack".
private struct SettingsPickerStyle: ViewModifier {
    @Environment(\.dynamicTypeSize) private var typeSize

    func body(content: Content) -> some View {
        if typeSize.isAccessibilitySize {
            content.pickerStyle(.navigationLink)
        } else {
            content.pickerStyle(.menu)
        }
    }
}

extension View {
    fileprivate func settingsPickerStyle() -> some View { modifier(SettingsPickerStyle()) }
}

#Preview {
    Form { PreferencesSection(profile: .preview) }
        .modelContainer(for: UserProfile.self, inMemory: true)
}

#Preview("Accessibility 5") {
    Form { PreferencesSection(profile: .preview) }
        .modelContainer(for: UserProfile.self, inMemory: true)
        .dynamicTypeSize(.accessibility5)
}
