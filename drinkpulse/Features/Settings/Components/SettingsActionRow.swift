import SwiftUI

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
        SettingsSection("DATA") {
            SettingsActionRow(title: "Export", systemImage: "square.and.arrow.up") {}
            Divider()
            SettingsActionRow(title: "Delete all", systemImage: "trash",
                              role: .destructive) {}
        }
        .padding()
    }
    .background(Color.dpAmber.opacity(0.04))
}
