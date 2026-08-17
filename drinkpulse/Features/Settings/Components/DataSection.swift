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
        .background {
            Color.clear.fileImporter(
                isPresented: $showDPImporter,
                allowedContentTypes: [.json]
            ) { result in handleDPImport(result) }
        }
        .background {
            Color.clear.fileImporter(
                isPresented: $showDCImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText]
            ) { result in prepareDCImport(result) }
        }
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
        .alert(
            String(localized: "settings.data.deleteAll.title"),
            isPresented: $showDeleteConfirm
        ) {
            Button(String(localized: "action.deleteAll"), role: .destructive) { deleteAllData() }
            Button(String(localized: "action.cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "settings.data.deleteAll.message"))
        }
        .background {
            Color.clear.fileExporter(
                isPresented: $showExporter,
                document: pendingExport.map(BackupDocument.init),
                contentType: .json,
                defaultFilename: pendingExport.map { ($0.fileName as NSString).deletingPathExtension }
            ) { result in
                pendingExport = nil
                handleExportResult(result)
            }
        }
        .alert(
            String(localized: "settings.data.export.success.title"),
            isPresented: $showExportSuccess
        ) {
            Button(String(localized: "action.ok"), role: .cancel) { }
        } message: {
            Text(String(localized: "settings.data.export.success.message"))
        }
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

    private func startExport() {
        let descriptor = FetchDescriptor<ConsumptionEvent>(
            sortBy: [SortDescriptor(\.consumptionDate)]
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
