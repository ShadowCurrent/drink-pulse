import SwiftUI

/// Full-screen error state shown when `StoreBootstrap.makeContainer` fails
/// even after its own internal non-destructive recovery attempt (STARTUP-03,
/// D-05, D-06). Replaces the entire app content — never an `.alert()` over
/// stale content, and never a crash.
///
/// Follows `HistoryView.emptyState`'s established `ContentUnavailableView`
/// idiom (UI-SPEC "Source of truth for reuse"), with a custom `actions:`
/// closure for Retry (accent, the screen's only tinted element) and Share
/// Diagnostic Details (plain/bordered — Retry-first hierarchy).
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

            // Visible on-screen, not only inside the share sheet (D-06):
            // a coarse, non-PII category string only — never
            // error.localizedDescription or a file path (D-08, Pitfall 1).
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
