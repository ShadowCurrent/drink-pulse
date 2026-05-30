import Foundation
import SwiftData

struct ImportResult {
    let imported: Int
    let skipped:  Int
    let failed:   Int
    let errors:   [String]
}

struct DataImporter {

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    @MainActor
    func importData(_ data: Data, into context: ModelContext) throws -> ImportResult {
        let bundle   = try Self.decoder.decode(ExportBundle.self, from: data)
        let existing = (try? context.fetch(FetchDescriptor<ConsumptionEvent>())) ?? []

        var imported = 0, skipped = 0, failed = 0
        var errors: [String] = []

        for record in bundle.events {
            if DataImporter.isDuplicate(record.timestamp, volumeMl: record.volumeMl, abv: record.abv, in: existing) {
                skipped += 1
                continue
            }
            guard let category = DrinkCategory(rawValue: record.category) else {
                failed += 1
                errors.append("Unknown category '\(record.category)'")
                continue
            }
            context.insert(ConsumptionEvent(
                timestamp:  record.timestamp,
                volumeMl:   record.volumeMl,
                abv:        record.abv,
                name:       record.name,
                category:   category,
                icon:       record.icon,
                customName: record.customName,
                notes:      record.notes,
                price:      record.price
            ))
            imported += 1
        }

        return ImportResult(imported: imported, skipped: skipped, failed: failed, errors: errors)
    }

    static func isDuplicate(
        _ timestamp: Date, volumeMl: Double, abv: Double,
        in existing: [ConsumptionEvent]
    ) -> Bool {
        existing.contains {
            abs($0.timestamp.timeIntervalSince(timestamp)) < 1.0 &&
            $0.volumeMl == volumeMl &&
            abs($0.abv - abv) < 0.001
        }
    }
}
