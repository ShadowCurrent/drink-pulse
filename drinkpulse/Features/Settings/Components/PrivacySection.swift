import SwiftUI

/// Privacy & Security: App Lock is managed by iOS, so the row opens the app's page in the
/// Settings app (UIKit docs, `UIApplication.openSettingsURLString`).
struct PrivacySection: View {
    var body: some View {
        Section {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link(destination: url) {
                    HStack {
                        Label(String(localized: "settings.systemLock"), systemImage: "lock.shield")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
            }
        } header: {
            Text(String(localized: "settings.section.privacy"))
                .foregroundStyle(Color.dpSecondaryText)
        } footer: {
            Text(String(localized: "settings.systemLock.footer"))
                .foregroundStyle(Color.dpSecondaryText)
        }
    }
}

#Preview {
    Form { PrivacySection() }
}
