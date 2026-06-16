import Foundation

nonisolated struct ExportBundle: Codable {
    let version: Int
    let exportedAt: Date
    let events: [ExportRecord]
    let profile: ProfileRecord?

    init(events: [ExportRecord], profile: ProfileRecord? = nil) {
        self.version    = 2
        self.exportedAt = .now
        self.events     = events
        self.profile    = profile
    }
}
