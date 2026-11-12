import SwiftUI

struct AppVersionFooter: View {
    var info: AppVersionInfo = .current

    var body: some View {
        Text(info.displayText)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .accessibilityIdentifier("settings.appVersion")
    }
}

#Preview("Release-like") {
    AppVersionFooter(info: AppVersionInfo(infoDictionary: [
        "CFBundleShortVersionString": "1.0",
        "CFBundleVersion": "1",
    ]))
    .padding()
}
