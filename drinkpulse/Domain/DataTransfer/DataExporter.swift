import Foundation

struct DataExporter {

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    func encode(_ events: [ConsumptionEvent]) throws -> Data {
        let bundle = ExportBundle(events: events.map(ExportRecord.init))
        return try Self.encoder.encode(bundle)
    }

    func writeTempFile(for events: [ConsumptionEvent], date: Date = .now) throws -> URL {
        let data = try encode(events)
        let url  = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(for: date))
        try data.write(to: url, options: .atomic)
        return url
    }

    func fileName(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return "drinkpulse-backup-\(fmt.string(from: date)).json"
    }
}
