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

/// Full-width tappable row used for action buttons inside a `SettingsSection`.
struct SettingsActionRow: View {
    let title: String
    let systemImage: String
    var role: ButtonRole?
    var trailingSystemImage: String?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                if let trailingSystemImage {
                    Image(systemName: trailingSystemImage)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(role == .destructive ? Color.red : .primary)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            SettingsSection("APPEARANCE") {
                SettingsRow("Mode") { Text("System").foregroundStyle(.secondary) }
            }
            SettingsSection("DATA") {
                SettingsActionRow(title: "Export", systemImage: "square.and.arrow.up") {}
                Divider()
                SettingsActionRow(title: "Delete all", systemImage: "trash",
                                  role: .destructive) {}
            }
        }
        .padding()
    }
    .background(Color.dpAmber.opacity(0.04))
}
