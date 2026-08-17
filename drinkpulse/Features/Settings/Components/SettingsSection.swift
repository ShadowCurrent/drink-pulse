import SwiftUI

struct SettingsSection<Content: View>: View {
    let titleKey: String.LocalizationValue?
    @ViewBuilder var content: Content

    init(_ titleKey: String.LocalizationValue, @ViewBuilder content: () -> Content) {
        self.titleKey = titleKey
        self.content = content()
    }

    init(@ViewBuilder content: () -> Content) {
        self.titleKey = nil
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let titleKey {
                Text(String(localized: titleKey))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dpGlassCard()
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            SettingsSection("APPEARANCE") {
                SettingsRow("Mode") { Text("System").foregroundStyle(.secondary) }
            }
            SettingsSection {
                SettingsRow("Titleless") { Text("No header").foregroundStyle(.secondary) }
            }
        }
        .padding()
    }
    .background(Color.dpAmber.opacity(0.04))
}
