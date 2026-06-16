import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConsumptionEvent.timestamp) private var events: [ConsumptionEvent]
    @Query private var profiles: [UserProfile]

    @State private var showDPImporter = false
    @State private var showDCImporter = false
    @State private var pendingDC: (csv: String, count: Int)?
    @State private var importResult: ImportResult?
    @State private var importError: String?
    @State private var showDeleteConfirm = false

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
    }

    // MARK: - Export row

    private var exportRow: some View {
        // Lazy: BackupExport snapshots value records here, but the JSON encode and
        // temp-file write only happen inside the share sheet's transfer closure —
        // so full user history never touches disk unless the user actually shares.
        let export = BackupExport(events: events, profile: profiles.first)
        return ShareLink(
            item: export,
            preview: SharePreview(
                export.fileName,
                image: Image(systemName: "doc.text")
            )
        ) {
            Label(String(localized: "settings.data.export"),
                  systemImage: "square.and.arrow.up")
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
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
