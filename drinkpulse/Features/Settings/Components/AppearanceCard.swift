import SwiftUI

struct AppearanceCard: View {
    @AppStorage("dp_theme") private var theme: DPTheme = .ember
    @AppStorage("dp_color_scheme") private var colorSchemeRaw: String = "system"

    var body: some View {
        VStack(spacing: 0) {
            themeRow
            Divider().padding(.leading, 16)
            modeRow
        }
        .frame(maxWidth: .infinity)
        .dpGlassCard()
        .padding(.bottom, 16)
    }

    private var themeRow: some View {
        SettingsRow(String(localized: "settings.appearance.theme")) {
            HStack(spacing: 10) {
                ForEach(DPTheme.allCases, id: \.self) { option in
                    ThemeSwatch(option: option, isSelected: theme == option)
                        .onTapGesture { theme = option }
                }
            }
        }
    }

    private var modeRow: some View {
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
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack(alignment: .leading, spacing: 6) {
            Text("APPEARANCE")
                .font(.footnote).foregroundStyle(.secondary).textCase(.uppercase)
                .padding(.horizontal, 4)
            AppearanceCard()
        }
        .padding(16)
    }
}
