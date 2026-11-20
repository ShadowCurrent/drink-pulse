import SwiftUI

/// The "Open Settings" row shown under a toggle whose permission was denied: opens the app's
/// page in the Settings app (UIKit docs, `UIApplication.openSettingsURLString`).
struct OpenSettingsRow: View {
    let title: String

    var body: some View {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            Link(destination: url) {
                HStack {
                    Label(title, systemImage: "gearshape")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

#Preview {
    Form { OpenSettingsRow(title: "Open Settings") }
}
