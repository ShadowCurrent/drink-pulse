import OSLog
import SwiftData
import SwiftUI

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
            enabled = false
            permissionDenied = true
        }
    }

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
        do {
            try modelContext.save()
        } catch {
            logger.error("Health backfill context save failed: \(error.localizedDescription)")
        }
    }

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
