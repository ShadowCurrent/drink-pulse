import Foundation

nonisolated struct ExportBundle: Codable {
    let version: Int
    let exportedAt: Date
    let events: [ExportRecord]
    /// Drink templates (plan-0023). Optional + absent in pre-0023 backups →
    /// decodes nil. Back-compatible additive key; no version bump needed.
    let templates: [TemplateRecord]?
    let profile: ProfileRecord?

    init(events: [ExportRecord], templates: [TemplateRecord]? = nil, profile: ProfileRecord? = nil) {
        self.version    = 2
        self.exportedAt = .now
        self.events     = events
        self.templates  = templates
        self.profile    = profile
    }
}
