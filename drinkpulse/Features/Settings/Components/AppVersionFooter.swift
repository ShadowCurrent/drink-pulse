import SwiftUI

struct AppVersionFooter: View {
    var info: AppVersionInfo = .current

    var body: some View {
        Text(info.displayText)
            .font(.footnote)
            .foregroundStyle(Color.dpSecondaryText)
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

#Preview("Debug-like") {
    AppVersionFooter(info: AppVersionInfo(
        infoDictionary: ["CFBundleShortVersionString": "1.0", "CFBundleVersion": "1"],
        buildDate: Date(timeIntervalSince1970: 1_794_000_000),
        gitCommit: "bd2fec0",
        isDebug: true
    ))
    .padding()
}

#Preview("AX5") {
    AppVersionFooter(info: AppVersionInfo(
        infoDictionary: ["CFBundleShortVersionString": "1.0", "CFBundleVersion": "1"],
        buildDate: Date(timeIntervalSince1970: 1_794_000_000),
        isDebug: true
    ))
    .padding()
    .dynamicTypeSize(.accessibility5)
}
