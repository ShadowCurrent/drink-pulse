import SwiftUI

struct StartupErrorView: View {
    let error: StartupError
    let isRetrying: Bool
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "startup.error.title"), systemImage: "exclamationmark.triangle")
        } description: {
            Text(String(localized: "startup.error.body"))
        } actions: {
            Button(action: onRetry) {
                if isRetrying {
                    ProgressView()
                } else {
                    Text(String(localized: "startup.error.retry"))
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRetrying)
            .accessibilityLabel(String(localized: "startup.error.retry.accessibilityLabel"))
            .accessibilityValue(isRetrying ? String(localized: "startup.error.retry.inProgress") : "")

            Text(error.diagnosticSummary)
                .font(.caption)
                .foregroundStyle(.secondary)

            ShareLink(item: error.diagnosticSummary) {
                Text(String(localized: "startup.error.contact"))
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(String(localized: "startup.error.contact.accessibilityLabel"))
        }
    }
}

#Preview {
    StartupErrorView(error: .storeUnavailable, isRetrying: false, onRetry: {})
}

#Preview("Retrying") {
    StartupErrorView(error: .storeUnavailable, isRetrying: true, onRetry: {})
}
