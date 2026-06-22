import Foundation
import CoreTransferable
import UniformTypeIdentifiers

/// Lazily-encoded backup payload. Mapping the SwiftData models into value
/// records happens up front on the main actor (cheap), but the JSON encoding is
/// deferred to `encoded()` — driven off-main by `BackupDocument.fileWrapper` via
/// `.fileExporter`, so it only runs when the user picks a save destination,
/// never eagerly on every Settings appearance. Keeps full user history off disk
/// until the user actually exports. (Also conforms to `Transferable` for reuse.)
struct BackupExport: Transferable, Sendable {
    let events: [ExportRecord]
    let profile: ProfileRecord?
    let fileName: String

    @MainActor
    init(events: [ConsumptionEvent], profile: UserProfile?, date: Date = .now) {
        self.events = events.map(ExportRecord.init)
        self.profile = profile.map(ProfileRecord.init)
        self.fileName = Self.fileName(for: date)
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { export in
            SentTransferredFile(try export.writeTempFile())
        }
        .suggestedFileName { $0.fileName }
    }

    /// Serializes the snapshot to JSON. Pure over value types — runs off the main
    /// actor inside the transfer closure, only when the user shares.
    func encoded() throws -> Data {
        let bundle = ExportBundle(events: events, profile: profile)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(bundle)
    }

    /// Encodes and writes the backup to a temp file. Called lazily by the transfer
    /// representation when the user actually invokes the share sheet.
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
