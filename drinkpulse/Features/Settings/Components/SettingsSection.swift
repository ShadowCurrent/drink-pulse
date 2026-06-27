import SwiftUI

/// A titled settings group rendered as a Liquid Glass card, matching the
/// `dpGlassCard` surfaces used across Dashboard / Insights / History. Replaces
/// the opaque `.insetGrouped` List rows that made Settings the odd screen out.
struct SettingsSection<Content: View>: View {
    let titleKey: String.LocalizationValue
    @ViewBuilder var content: Content

    init(_ titleKey: String.LocalizationValue, @ViewBuilder content: () -> Content) {
        self.titleKey = titleKey
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: titleKey))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

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
        SettingsSection("APPEARANCE") {
            SettingsRow("Mode") { Text("System").foregroundStyle(.secondary) }
        }
        .padding()
    }
    .background(Color.dpAmber.opacity(0.04))
}
