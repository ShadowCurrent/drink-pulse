import Foundation

@MainActor
struct DataExporter {

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    func encode(_ events: [ConsumptionEvent], profile: UserProfile? = nil) throws -> Data {
        let profileRecord = profile.map(ProfileRecord.init)
        let bundle = ExportBundle(events: events.map(ExportRecord.init), profile: profileRecord)
        return try Self.encoder.encode(bundle)
    }

    func writeTempFile(
        for events: [ConsumptionEvent],
        profile: UserProfile? = nil,
        date: Date = .now
    ) throws -> URL {
        let data = try encode(events, profile: profile)
        let url  = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(for: date))
        try data.write(to: url, options: .atomic)
        return url
    }

    func fileName(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return "drinkpulse-backup-\(fmt.string(from: date)).json"
    }

    /// Stable content signature used to detect changes (including edits, not just count changes).
    nonisolated static func contentSignature(events: [ConsumptionEvent], profile: UserProfile?) -> String {
        var hasher = Hasher()
        for e in events {
            hasher.combine(e.timestamp)
            hasher.combine(e.volumeMl)
            hasher.combine(e.abv)
            hasher.combine(e.name)
            hasher.combine(e.notes)
            hasher.combine(e.price)
        }
        if let p = profile {
            hasher.combine(p.bodyWeightKg)
            hasher.combine(p.biologicalSex.rawValue)
            hasher.combine(p.guidelineChoice.rawValue)
            hasher.combine(p.weeklyGoalGrams)
            hasher.combine(p.unitSystem.rawValue)
            hasher.combine(p.currency)
            hasher.combine(p.abvPrecisionPermille)
            hasher.combine(p.alcoholUnit.rawValue)
        }
        return String(hasher.finalize())
    }
}
