import OSLog
import SwiftData
import SwiftUI

/// Settings → Weekly Summary card (phase-01, v1.1). An opt-in weekly local
/// notification reporting week-over-week pure-alcohol grams change. Off by
/// default; toggling on triggers the authorization request and an immediate
/// (re)schedule against current data. Fixed 9am schedule — no time picker
/// (unlike `ReminderSection`, which lets the user pick a fire time).
///
/// Mirrors `ReminderSection`'s exact card shape (`SettingsSection` glass card
/// with a toggle, inline hint, denied → "Open Settings" deep link), minus the
/// time row.
struct WeeklySummarySection: View {
    @AppStorage(AppStorageKeys.weeklySummaryEnabled) private var enabled = false
    @Environment(\.modelContext) private var modelContext
    @State private var permissionDenied = false
    /// Monotonically incremented on every toggle interaction (on or off).
    /// `enable()` captures the value in effect when it starts and re-checks
    /// it after resuming from its `await`s; a mismatch means a later toggle
    /// action (e.g. the user turning it back off) has superseded this one,
    /// so `enable()` bails instead of re-arming a notification the user just
    /// turned off (WR-02).
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
            // A newer toggle action (e.g. the user turning it back off while
            // this one was suspended on `requestAuthorization()`) has
            // superseded this one — bail without re-arming (WR-02).
            guard generation == toggleGeneration else { return }
            guard granted else {
                enabled = false
                permissionDenied = true
                return
            }
            permissionDenied = false
            // Set the flag before scheduling: `scheduleIfEnabled` re-reads
            // `AppStorageKeys.weeklySummaryEnabled` from UserDefaults directly,
            // so calling it first would make the schedule a no-op.
            enabled = true
            await service.scheduleIfEnabled(context: modelContext)
            // Re-check once more after the (potentially slow) schedule call:
            // if the user turned it off while scheduling was in flight, undo
            // the re-arm immediately rather than leaving a stale notification.
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
