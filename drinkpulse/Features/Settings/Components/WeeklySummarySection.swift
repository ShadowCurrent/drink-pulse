import OSLog
import SwiftData
import SwiftUI

struct WeeklySummarySection: View {
    @AppStorage(AppStorageKeys.weeklySummaryEnabled) private var enabled = false
    @Environment(\.modelContext) private var modelContext
    @State private var permissionDenied = false
    @State private var toggleGeneration = 0

    private let service = WeeklySummaryService()
    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "WeeklySummarySection")

    var body: some View {
        SettingsSection("settings.section.weeklySummary") {
            SettingsRow(String(localized: "settings.weeklySummary.toggle")) {
                Toggle(isOn: toggleBinding) {
                    Text(String(localized: "settings.weeklySummary.toggle"))
                }
                .labelsHidden()
                .accessibilityLabel(String(localized: "settings.weeklySummary.toggle"))
            }

            Divider()
            Text(String(localized: permissionDenied ? "settings.weeklySummary.denied" : "settings.weeklySummary.hint"))
                .font(.footnote)
                .foregroundStyle(permissionDenied ? Color.red : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)

            if permissionDenied {
                Divider()
                SettingsActionRow(
                    title: String(localized: "settings.reminder.openSettings"),
                    systemImage: "gearshape",
                    trailingSystemImage: "arrow.up.right.square"
                ) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    // MARK: - Bindings

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { enabled },
            set: { newValue in
                toggleGeneration += 1
                if newValue {
                    let generation = toggleGeneration
                    Task { await enable(generation: generation) }
                } else {
                    enabled = false
                    permissionDenied = false
                    Task { await service.cancel() }
                }
            }
        )
    }

    // MARK: - Actions

    private func enable(generation: Int) async {
        do {
            let granted = try await service.requestAuthorization()
            guard generation == toggleGeneration else { return }
            guard granted else {
                enabled = false
                permissionDenied = true
                return
            }
            permissionDenied = false
            enabled = true
            await service.scheduleIfEnabled(context: modelContext)
            guard generation == toggleGeneration else {
                await service.cancel()
                return
            }
        } catch {
            guard generation == toggleGeneration else { return }
            enabled = false
            permissionDenied = true
            logger.error("Weekly summary enable failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    return ScrollView {
        VStack(spacing: 20) {
            WeeklySummarySection()
        }
        .padding()
    }
    .modelContainer(container)
    .background(Color.dpAccent.opacity(0.04))
}
