import OSLog
import SwiftData
import SwiftUI

/// Settings → Apple Health card (plan-0036). An opt-in, write-only mirror that
/// logs your drinks to Apple Health. Off by default; toggling on triggers the
/// Health authorization request. On the first enable, if there is existing
/// history, the user is asked whether to also add their past drinks (backfill).
///
/// Mirrors `ReminderSection`: a `SettingsSection` glass card with a toggle, an
/// inline hint, and a denied → "Open Settings" deep link. The shared
/// `HealthService` comes from the environment (provided at the app root) so this
/// screen, onboarding and the write hooks all use the same instance.
struct HealthSection: View {
    @AppStorage(AppStorageKeys.healthWriteEnabled) private var enabled = false
    @Environment(\.healthService) private var healthService
    @Environment(\.modelContext) private var modelContext

    @State private var permissionDenied = false
    @State private var showBackfillDialog = false
    @State private var pendingBackfillEvents: [ConsumptionEvent] = []

    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "HealthSection")

    var body: some View {
        SettingsSection("settings.section.health") {
            SettingsRow(String(localized: "settings.health.toggle")) {
                Toggle(isOn: toggleBinding) {
                    Text(String(localized: "settings.health.toggle"))
                }
                .labelsHidden()
                .accessibilityLabel(String(localized: "settings.health.toggle"))
            }

            Divider()
            Text(String(localized: permissionDenied ? "settings.health.denied" : "settings.health.hint"))
                .font(.footnote)
                .foregroundStyle(permissionDenied ? Color.red : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)

            if permissionDenied {
                Divider()
                SettingsActionRow(
                    title: String(localized: "settings.health.openSettings"),
                    systemImage: "gearshape",
                    trailingSystemImage: "arrow.up.right.square"
                ) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .confirmationDialog(
            String(localized: "settings.health.backfill.title"),
            isPresented: $showBackfillDialog,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settings.health.backfill.confirm")) {
                Task { await runBackfill() }
            }
            .accessibilityLabel(String(localized: "settings.health.backfill.confirm"))
            Button(String(localized: "settings.health.backfill.cancel"), role: .cancel) {
                pendingBackfillEvents = []
            }
            .accessibilityLabel(String(localized: "settings.health.backfill.cancel"))
        } message: {
            Text(String(localized: "settings.health.backfill.message"))
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
                    // Disabling just stops future mirroring; existing Health
                    // samples are left untouched (the user owns them in Health).
                    enabled = false
                    permissionDenied = false
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
            offerBackfillIfHistoryExists()
        case .denied, .notDetermined:
            // Mirror the Reminders denied path: flip back off and point the user
            // at system Settings to grant access.
            enabled = false
            permissionDenied = true
        }
    }

    /// On a successful enable, ask whether to also add past drinks — but only
    /// when there is history (a brand-new user just enables). Dedup makes the
    /// backfill idempotent, so re-enabling later re-links rather than duplicates.
    private func offerBackfillIfHistoryExists() {
        let events = fetchEvents()
        guard !events.isEmpty else { return }
        pendingBackfillEvents = events
        showBackfillDialog = true
    }

    private func runBackfill() async {
        let events = pendingBackfillEvents
        pendingBackfillEvents = []
        guard let healthService, !events.isEmpty else { return }
        await healthService.backfill(events)
        // The service stamps each event's device-local `healthKitUUID` in place;
        // persist those so a later edit/delete can find its sample.
        do {
            try modelContext.save()
        } catch {
            logger.error("Health backfill context save failed: \(error.localizedDescription)")
        }
    }

    /// Lazily fetches events only when needed (first enable), so opening Settings
    /// never materializes the full history — mirrors `DataSection.startExport`.
    private func fetchEvents() -> [ConsumptionEvent] {
        let descriptor = FetchDescriptor<ConsumptionEvent>(
            sortBy: [SortDescriptor(\.consumptionDate)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
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
            HealthSection()
        }
        .padding()
    }
    .environment(\.healthService, HealthService())
    .modelContainer(container)
    .background(Color.dpAccent.opacity(0.04))
}
