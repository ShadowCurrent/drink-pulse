import SwiftUI
import UniformTypeIdentifiers

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
