import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct BackupExport: Transferable, Sendable {
    let events: [ExportRecord]
    let templates: [TemplateRecord]
    let profile: ProfileRecord?
    let fileName: String

    @MainActor
    init(events: [ConsumptionEvent], templates: [DrinkTemplate] = [], profile: UserProfile?, date: Date = .now) {
        self.events = events.map(ExportRecord.init)
        self.templates = templates.map(TemplateRecord.init)
        self.profile = profile.map(ProfileRecord.init)
        self.fileName = Self.fileName(for: date)
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { export in
            SentTransferredFile(try export.writeTempFile())
        }
        .suggestedFileName { $0.fileName }
    }

    func encoded() throws -> Data {
        let bundle = ExportBundle(events: events, templates: templates.isEmpty ? nil : templates, profile: profile)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(bundle)
    }

    func writeTempFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try encoded().write(to: url, options: .atomic)
        return url
    }

    static func fileName(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return "drinkpulse-backup-\(fmt.string(from: date)).json"
    }
}
