import OSLog
import SwiftData
import SwiftUI

/// Weekly summary rows inside `NotificationsSection`: toggle, Open Settings when denied. The
/// hint / denied line is the section footer, so `permissionDenied` is owned there.
struct WeeklySummaryRows: View {
    @AppStorage(AppStorageKeys.weeklySummaryEnabled) private var enabled = false
    @Environment(\.modelContext) private var modelContext
    @Binding var permissionDenied: Bool
    @State private var toggleGeneration = 0

    private let service = WeeklySummaryService()
    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "WeeklySummarySection")

    var body: some View {
        Toggle(String(localized: "settings.weeklySummary.toggle"), isOn: toggleBinding)

        if permissionDenied {
            OpenSettingsRow(title: String(localized: "settings.reminder.openSettings"))
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
    @Previewable @State var denied = false
    Form { WeeklySummaryRows(permissionDenied: $denied) }
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}
