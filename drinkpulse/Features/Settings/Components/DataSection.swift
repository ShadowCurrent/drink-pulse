import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConsumptionEvent.timestamp) private var events: [ConsumptionEvent]
    @Query private var profiles: [UserProfile]

    @State private var exportURL: URL?
    @State private var showDPImporter = false
    @State private var showDCImporter = false
    @State private var pendingDC: (csv: String, count: Int)?
    @State private var importResult: ImportResult?
    @State private var showDeleteConfirm = false

    var body: some View {
        Section {
            exportRow
            Button { showDPImporter = true } label: {
                Label(String(localized: "settings.data.importDP"),
                      systemImage: "square.and.arrow.down")
            }
            Button { showDCImporter = true } label: {
                Label(String(localized: "settings.data.importDC"),
                      systemImage: "square.and.arrow.down.fill")
            }
            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Label(String(localized: "settings.data.deleteAll"),
                      systemImage: "trash")
            }
        } header: {
            Text(String(localized: "settings.section.data"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .task(id: events.count) {
            exportURL = try? DataExporter().writeTempFile(for: events)
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
        Group {
            if let url = exportURL {
                ShareLink(
                    item: url,
                    preview: SharePreview(
                        url.lastPathComponent,
                        image: Image(systemName: "doc.text")
                    )
                ) {
                    Label(String(localized: "settings.data.export"),
                          systemImage: "square.and.arrow.up")
                }
            } else {
                Label(String(localized: "settings.data.export"),
                      systemImage: "square.and.arrow.up")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Import handlers

    private func handleDPImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return }
        importResult = try? DataImporter().importData(data, into: modelContext)
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
        profile.alcoholUnit = .units
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
