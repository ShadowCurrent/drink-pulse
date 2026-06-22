import SwiftUI
import UniformTypeIdentifiers

/// `FileDocument` wrapper around a `BackupExport`, used by SwiftUI's
/// `.fileExporter`. The expensive JSON encode lives in `fileWrapper`, which
/// SwiftUI calls on a background queue when the user confirms a save location —
/// so tapping Export never blocks the main actor. Export-only: the reading
/// initializer is unreachable.
struct BackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    let export: BackupExport

    init(export: BackupExport) {
        self.export = export
    }

    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadUnsupportedScheme)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try export.encoded())
    }
}
