import Foundation

struct ExportBundle: Codable {
    let version: Int
    let exportedAt: Date
    let events: [ExportRecord]

    init(events: [ExportRecord]) {
        self.version    = 1
        self.exportedAt = .now
        self.events     = events
    }
}
