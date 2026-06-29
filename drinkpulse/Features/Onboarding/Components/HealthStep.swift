import SwiftUI

/// Onboarding → Apple Health opt-in (plan-0036, W8). A new optional 4th step
/// after Guideline. **Off by default** — the user must manually toggle it on,
/// which triggers the Health authorization request (read+write). If access is
/// not granted the toggle flips back off and an inline "enable later in
/// Settings" hint appears; it never blocks finishing. There is **no backfill**
/// here: a brand-new user has no history to mirror yet.
///
/// Writes the SAME `dp_health_write_enabled` flag and reads the SAME
/// `HealthService` (from the environment, provided at the app root) as the
/// Settings card, so the two stay in sync. The "Done" button finishes
/// onboarding regardless of the toggle state — leaving it untouched keeps
/// Health off.
struct HealthStep: View {
    let onDone: () -> Void

    @AppStorage(AppStorageKeys.healthWriteEnabled) private var enabled = false
    @Environment(\.healthService) private var healthService
    @State private var permissionDenied = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "onboarding.health.title"))
                    .font(.largeTitle.bold())
                    .padding(.top, 16)

                Text(String(localized: "onboarding.health.body"))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Toggle(isOn: toggleBinding) {
                    Text(String(localized: "onboarding.health.toggle"))
                        .font(.body)
                }
                .accessibilityLabel(String(localized: "onboarding.health.toggle"))

                Text(String(localized: permissionDenied
                                      ? "onboarding.health.denied"
                                      : "onboarding.health.hint"))
                    .font(.footnote)
                    .foregroundStyle(permissionDenied ? Color.red : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onDone) {
                Text(String(localized: "onboarding.health.done"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(String(localized: "onboarding.health.done.hint"))
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Bindings

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { enabled },
            set: { newValue in
                if newValue {
                    Task { await enable() }
                } else {
                    // Turning off just stops future mirroring; nothing to undo on
                    // a brand-new account (no samples written yet).
                    enabled = false
                    permissionDenied = false
                }
            }
        )
    }

    // MARK: - Actions

    /// Requests authorization and reflects the result inline. Mirrors
    /// `HealthSection.enable()` minus the backfill (empty history at onboarding).
    private func enable() async {
        guard let healthService else {
            enabled = false
            return
        }
        _ = await healthService.requestAuthorization()
        switch healthService.authorizationStatus() {
        case .authorized:
            permissionDenied = false
            enabled = true
        case .denied, .notDetermined:
            // Flip back off and point the user at Settings — don't block finishing.
            enabled = false
            permissionDenied = true
        }
    }
}

#Preview {
    HealthStep(onDone: {})
        .environment(\.healthService, HealthService())
}
