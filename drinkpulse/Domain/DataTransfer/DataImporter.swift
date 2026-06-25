import Foundation
import SwiftData

enum ImportError: LocalizedError {
    case unsupportedVersion(Int)
    case decodeFailure(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let v):
            return String(format: String(localized: "import.error.unsupportedVersion"), v)
        case .decodeFailure:
            return String(localized: "import.error.decodeFailure")
        }
    }
}

struct ImportResult {
    let imported: Int
    let skipped:  Int
    let failed:   Int
    let errors:   [String]
}

struct DataImporter {

    static let supportedVersions: Set<Int> = [1, 2]

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    @MainActor
    func importData(_ data: Data, into context: ModelContext) throws -> ImportResult {
        let bundle: ExportBundle
        do {
            bundle = try Self.decoder.decode(ExportBundle.self, from: data)
        } catch {
            throw ImportError.decodeFailure(underlying: error)
        }

        guard Self.supportedVersions.contains(bundle.version) else {
            throw ImportError.unsupportedVersion(bundle.version)
        }

        var imported = 0, skipped = 0, failed = 0
        var errors: [String] = []

        let existing = (try? context.fetch(FetchDescriptor<ConsumptionEvent>())) ?? []
        for record in bundle.events {
            if DataImporter.isDuplicate(record.timestamp, volumeMl: record.volumeMl,
                                        abv: record.abv, quantity: record.quantity, in: existing) {
                skipped += 1
                continue
            }
            guard let category = DrinkCategory(rawValue: record.category) else {
                failed += 1
                errors.append("Unknown category '\(record.category)'")
                continue
            }
            context.insert(ConsumptionEvent(
                timestamp:   record.timestamp,
                volumeMl:    record.volumeMl,
                abv:         record.abv,
                quantity:    record.quantity,
                enteredUnit: record.enteredUnit.flatMap(UnitSystem.init(rawValue:)),
                name:        record.name,
                category:   category,
                icon:       record.icon,
                customName: record.customName,
                notes:      record.notes,
                price:      record.price,
                priceCurrency: record.priceCurrency
            ))
            imported += 1
        }

        if let profileRecord = bundle.profile {
            upsertProfile(profileRecord, into: context)
        }

        return ImportResult(imported: imported, skipped: skipped, failed: failed, errors: errors)
    }

    static func isDuplicate(
        _ timestamp: Date, volumeMl: Double, abv: Double, quantity: Int = 1,
        in existing: [ConsumptionEvent]
    ) -> Bool {
        existing.contains {
            abs($0.timestamp.timeIntervalSince(timestamp)) < 1.0 &&
            $0.volumeMl == volumeMl &&
            abs($0.abv - abv) < 0.001 &&
            $0.quantity == quantity
        }
    }

    // MARK: - Private

    @MainActor
    private func upsertProfile(_ record: ProfileRecord, into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        if let profile = existing.first {
            record.apply(to: profile)
        } else {
            let profile = UserProfile()
            record.apply(to: profile)
            context.insert(profile)
        }
    }
}
