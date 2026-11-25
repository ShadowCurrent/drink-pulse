import SwiftUI

struct HealthStep: View {
    let onDone: () -> Void
    private let weeklySummaryService: WeeklySummaryService

    init(onDone: @escaping () -> Void, weeklySummaryService: WeeklySummaryService) {
        self.onDone = onDone
        self.weeklySummaryService = weeklySummaryService
    }

    init(onDone: @escaping () -> Void) {
        self.init(onDone: onDone, weeklySummaryService: WeeklySummaryService())
    }

    @AppStorage(AppStorageKeys.healthWriteEnabled) private var enabled = false
    @Environment(\.healthService) private var healthService
    @State private var permissionDenied = false

    @AppStorage(AppStorageKeys.weeklySummaryEnabled) private var weeklySummaryEnabled = false
    @State private var weeklySummaryPermissionDenied = false
    @State private var weeklySummaryToggleGeneration = 0

    var body: some View {
        OnboardingStepLayout(
            buttonTitle: String(localized: "onboarding.health.done"),
            buttonHint: String(localized: "onboarding.health.done.hint"),
            action: onDone
        ) {
            OnboardingHeading(
                title: String(localized: "onboarding.health.title"),
                message: String(localized: "onboarding.health.body")
            )
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer(minLength: 16)

            // Content-layer card on `BrandSurface`, not a material (HIG Materials, D0048-10).
            OnboardingCard {
                toggleRow(
                    title: String(localized: "onboarding.health.toggle"),
                    isOn: toggleBinding,
                    hint: String(localized: permissionDenied
                                 ? "onboarding.health.denied" : "onboarding.health.hint"),
                    denied: permissionDenied
                )
                Divider().padding(.leading, CardMetrics.padding)
                toggleRow(
                    title: String(localized: "onboarding.health.weeklySummary.toggle"),
                    isOn: weeklySummaryToggleBinding,
                    hint: String(localized: weeklySummaryPermissionDenied
                                 ? "onboarding.health.weeklySummary.denied"
                                 : "onboarding.health.weeklySummary.hint"),
                    denied: weeklySummaryPermissionDenied
                )
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 16)
        }
    }

    private func toggleRow(title: String, isOn: Binding<Bool>, hint: String, denied: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: isOn) {
                Text(title).font(.body)
            }
            .accessibilityLabel(title)

            Text(hint)
                .font(.footnote)
                .foregroundStyle(denied ? Color.dpDeniedText : Color.dpSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(CardMetrics.padding)
    }

    // MARK: - Bindings

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { enabled },
            set: { newValue in
                if newValue {
                    Task { await enable() }
                } else {
                    enabled = false
                    permissionDenied = false
                }
            }
        )
    }

    private var weeklySummaryToggleBinding: Binding<Bool> {
        Binding(
            get: { weeklySummaryEnabled },
            set: { newValue in
                weeklySummaryToggleGeneration += 1
                if newValue {
                    let generation = weeklySummaryToggleGeneration
                    Task { await enableWeeklySummary(generation: generation) }
                } else {
                    Task { await disableWeeklySummary() }
                }
            }
        )
    }

    // MARK: - Actions

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
            enabled = false
            permissionDenied = true
        }
    }

    private func enableWeeklySummary(generation: Int) async {
        do {
            let granted = try await weeklySummaryService.requestAuthorization()
            guard generation == weeklySummaryToggleGeneration else { return }
            guard granted else {
                weeklySummaryEnabled = false
                weeklySummaryPermissionDenied = true
                return
            }
            weeklySummaryPermissionDenied = false
            weeklySummaryEnabled = true
        } catch {
            guard generation == weeklySummaryToggleGeneration else { return }
            weeklySummaryEnabled = false
            weeklySummaryPermissionDenied = true
        }
    }

    func disableWeeklySummary() async {
        weeklySummaryEnabled = false
        weeklySummaryPermissionDenied = false
        await weeklySummaryService.cancel()
    }
}

#Preview("Light") {
    HealthStep(onDone: {})
        .environment(\.healthService, HealthService())
        .background { BrandBackdrop().ignoresSafeArea() }
}

#Preview("Dark") {
    HealthStep(onDone: {})
        .environment(\.healthService, HealthService())
        .background { BrandBackdrop().ignoresSafeArea() }
        .preferredColorScheme(.dark)
}

#Preview("Accessibility 5") {
    HealthStep(onDone: {})
        .environment(\.healthService, HealthService())
        .background { BrandBackdrop().ignoresSafeArea() }
        .dynamicTypeSize(.accessibility5)
}
