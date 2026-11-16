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

            Spacer(minLength: 16)

            VStack(spacing: 16) {
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

                VStack(spacing: 12) {
                    Toggle(isOn: weeklySummaryToggleBinding) {
                        Text(String(localized: "onboarding.health.weeklySummary.toggle"))
                            .font(.body)
                    }
                    .accessibilityLabel(String(localized: "onboarding.health.weeklySummary.toggle"))

                    Text(String(localized: weeklySummaryPermissionDenied
                                          ? "onboarding.health.weeklySummary.denied"
                                          : "onboarding.health.weeklySummary.hint"))
                        .font(.footnote)
                        .foregroundStyle(weeklySummaryPermissionDenied ? Color.red : .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer(minLength: 16)
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

#Preview {
    HealthStep(onDone: {})
        .environment(\.healthService, HealthService())
}

#Preview("Accessibility 5") {
    HealthStep(onDone: {})
        .environment(\.healthService, HealthService())
        .dynamicTypeSize(.accessibility5)
}
