import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var showDPImporter = false
    @State private var showDCImporter = false
    @State private var pendingDC: (csv: String, count: Int)?
    @State private var importResult: ImportResult?
    @State private var importError: String?
    @State private var showDeleteConfirm = false
    @State private var pendingExport: BackupExport?
    @State private var showExporter = false
    @State private var exportError: String?
    @State private var showExportSuccess = false

    var body: some View {
        SettingsSection("settings.section.data") {
            exportRow
            Divider()
            SettingsActionRow(title: String(localized: "settings.data.importDP"),
                              systemImage: "square.and.arrow.down") { showDPImporter = true }
            Divider()
            SettingsActionRow(title: String(localized: "settings.data.importDC"),
                              systemImage: "square.and.arrow.down.fill") { showDCImporter = true }
            Divider()
            SettingsActionRow(title: String(localized: "settings.data.deleteAll"),
                              systemImage: "trash", role: .destructive) { showDeleteConfirm = true }
        }
        .fileImporter(isPresented: $showDPImporter, allowedContentTypes: [.json]) { result in
            handleDPImport(result)
        }
        .fileImporter(
            isPresented: $showDCImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in
            prepareDCImport(result)
        }
        // Confirm DrinkControl import
        .alert(
            String(localized: "settings.data.confirmDC.title"),
            isPresented: Binding(
                get: { pendingDC != nil },
                set: { if !$0 { pendingDC = nil } }
            )
        ) {
            Button(String(localized: "action.import")) { executeDCImport() }
            Button(String(localized: "action.cancel"), role: .cancel) { pendingDC = nil }
        } message: {
            if let p = pendingDC {
                Text(String(
                    format: String(localized: "settings.data.confirmDC.message"),
                    p.count
                ))
            }
        }
        // Import result
        .alert(
            String(localized: "settings.data.result.title"),
            isPresented: Binding(
                get: { importResult != nil },
                set: { if !$0 { importResult = nil } }
            )
        ) {
            Button(String(localized: "action.ok"), role: .cancel) { importResult = nil }
        } message: {
            if let r = importResult {
                Text(resultMessage(r))
            }
        }
        // Import error
        .alert(
            String(localized: "settings.data.importError.title"),
            isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )
        ) {
            Button(String(localized: "action.ok"), role: .cancel) { importError = nil }
        } message: {
            if let msg = importError {
                Text(msg)
            }
        }
        // Delete all data confirmation
        .alert(
            String(localized: "settings.data.deleteAll.title"),
            isPresented: $showDeleteConfirm
        ) {
            Button(String(localized: "action.deleteAll"), role: .destructive) { deleteAllData() }
            Button(String(localized: "action.cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "settings.data.deleteAll.message"))
        }
        // Export via the system save panel
        .fileExporter(
            isPresented: $showExporter,
            document: pendingExport.map(BackupDocument.init),
            contentType: .json,
            defaultFilename: pendingExport.map { ($0.fileName as NSString).deletingPathExtension }
        ) { result in
            pendingExport = nil
            handleExportResult(result)
        }
        // Export success
        .alert(
            String(localized: "settings.data.export.success.title"),
            isPresented: $showExportSuccess
        ) {
            Button(String(localized: "action.ok"), role: .cancel) { }
        } message: {
            Text(String(localized: "settings.data.export.success.message"))
        }
        // Export error
        .alert(
            String(localized: "settings.data.export.error.title"),
            isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )
        ) {
            Button(String(localized: "action.ok"), role: .cancel) { exportError = nil }
        } message: {
            if let msg = exportError {
                Text(msg)
            }
        }
    }

    // MARK: - Export row

    private var exportRow: some View {
        SettingsActionRow(title: String(localized: "settings.data.export"),
                          systemImage: "square.and.arrow.up") { startExport() }
    }

    /// Snapshots the backup payload and presents the save panel. Events are
    /// fetched **lazily here** (not via a screen-level `@Query`) so opening
    /// Settings never materializes the full history on the main thread — that
    /// eager fetch caused the multi-second load + flicker on large stores. Only
    /// the cheap value-record mapping runs here; the JSON encode is deferred to
    /// `BackupDocument.fileWrapper`, which SwiftUI runs off-main on save.
    private func startExport() {
        let descriptor = FetchDescriptor<ConsumptionEvent>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let events = (try? modelContext.fetch(descriptor)) ?? []
        let templates = (try? modelContext.fetch(FetchDescriptor<DrinkTemplate>())) ?? []
        pendingExport = BackupExport(events: events, templates: templates, profile: profiles.first)
        showExporter = true
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            showExportSuccess = true
        case .failure(let error):
            // The user dismissing the save panel surfaces as a cancellation —
            // not a real error, so don't alarm them with a failure alert.
            if (error as? CocoaError)?.code == .userCancelled { return }
            exportError = String(localized: "settings.data.export.error.message")
        }
    }

    // MARK: - Import handlers

    private func handleDPImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else {
            importError = String(localized: "import.error.decodeFailure")
            return
        }
        do {
            importResult = try DataImporter().importData(data, into: modelContext)
        } catch {
            importError = (error as? ImportError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func prepareDCImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let csv = try? String(contentsOf: url, encoding: .utf8) else { return }
        let count = DrinkControlImporter().previewCount(csv)
        pendingDC = (csv, count)
    }

    private func executeDCImport() {
        guard let p = pendingDC else { return }
        pendingDC = nil
        importResult = DrinkControlImporter().importCSV(p.csv, into: modelContext)
    }

    // MARK: - Delete all data

    private func deleteAllData() {
        try? modelContext.delete(model: ConsumptionEvent.self)
        try? modelContext.delete(model: DrinkTemplate.self)
        StoreBootstrap.clearRecoveredStores()
        // Reset profile to defaults instead of deleting it. Deleting while
        // SettingsForm holds a @Bindable reference causes a use-after-free
        // and freezes the Settings screen.
        guard let profile = profiles.first else { return }
        profile.bodyWeightKg = 70.0
        profile.biologicalSex = .male
        profile.dateOfBirth = nil
        profile.guidelineChoice = .who
        profile.weeklyGoalGrams = 100.0
        profile.unitSystem = .metric
        profile.currency = "USD"
        profile.abvPrecisionPermille = 5
        profile.alcoholUnit = .standardDrinks
        profile.touch()
    }

    // MARK: - Result message

    private func resultMessage(_ r: ImportResult) -> String {
        var parts = [String(format: String(localized: "settings.data.result.imported"), r.imported)]
        if r.skipped > 0 {
            parts.append(String(format: String(localized: "settings.data.result.skipped"), r.skipped))
        }
        if r.failed > 0 {
            parts.append(String(format: String(localized: "settings.data.result.failed"), r.failed))
        }
        return parts.joined(separator: "\n")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(UserProfile.preview)
    return ScrollView {
        DataSection()
            .padding()
    }
    .modelContainer(container)
}
