import Foundation
import SwiftData

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
        var byUUID: [UUID: ConsumptionEvent] = [:]
        for event in existing { byUUID[event.uuid] = event }

        for record in bundle.events {
            guard let category = DrinkCategory(rawValue: record.category) else {
                failed += 1
                errors.append("Unknown category '\(record.category)'")
                continue
            }

            if let uuid = record.uuid, let match = byUUID[uuid] {
                let incoming = record.modifiedDate ?? .distantPast
                if incoming > match.modifiedDate {
                    Self.apply(record, category: category, to: match)
                    imported += 1
                } else {
                    skipped += 1
                }
                continue
            }

            if record.uuid == nil,
               DataImporter.isDuplicate(record.consumptionDate, volumeMl: record.volumeMl,
                                        abv: record.abv, quantity: record.quantity, in: existing) {
                skipped += 1
                continue
            }

            let event = ConsumptionEvent(
                consumptionDate: record.consumptionDate,
                volumeMl:    record.volumeMl,
                abv:         record.abv,
                quantity:    record.quantity,
                enteredUnit: record.enteredUnit.flatMap(UnitSystem.init(rawValue:)),
                category:   category,
                icon:       record.icon,
                customName: record.customName,
                notes:      record.notes,
                price:      record.price,
                priceCurrency: record.priceCurrency,
                creationDate: record.creationDate ?? record.consumptionDate
            )
            if let uuid = record.uuid { event.uuid = uuid }
            event.modifiedDate = record.modifiedDate ?? record.consumptionDate
            context.insert(event)
            byUUID[event.uuid] = event
            imported += 1
        }

        importTemplates(bundle.templates ?? [], into: context)

        if let profileRecord = bundle.profile {
            upsertProfile(profileRecord, into: context)
        }

        return ImportResult(imported: imported, skipped: skipped, failed: failed, errors: errors)
    }

    static func isDuplicate(
        _ consumptionDate: Date, volumeMl: Double, abv: Double, quantity: Int = 1,
        in existing: [ConsumptionEvent]
    ) -> Bool {
        existing.contains {
            abs($0.consumptionDate.timeIntervalSince(consumptionDate)) < 1.0 &&
            $0.volumeMl == volumeMl &&
            abs($0.abv - abv) < 0.001 &&
            $0.quantity == quantity
        }
    }

    // MARK: - Private

    @MainActor
    private static func apply(_ record: ExportRecord, category: DrinkCategory, to event: ConsumptionEvent) {
        event.consumptionDate = record.consumptionDate
        event.volumeMl = record.volumeMl
        event.abv = record.abv
        event.quantity = record.quantity
        event.enteredUnit = record.enteredUnit.flatMap(UnitSystem.init(rawValue:))
        event.category = category
        event.icon = record.icon
        event.customName = record.customName
        event.notes = record.notes
        event.price = record.price
        event.priceCurrency = record.priceCurrency
        event.modifiedDate = record.modifiedDate ?? record.consumptionDate
    }

    @MainActor
    private func importTemplates(_ records: [TemplateRecord], into context: ModelContext) {
        guard !records.isEmpty else { return }
        let existing = (try? context.fetch(FetchDescriptor<DrinkTemplate>())) ?? []
        var byUUID: [UUID: DrinkTemplate] = [:]
        for template in existing { byUUID[template.uuid] = template }

        for record in records {
            guard let category = DrinkCategory(rawValue: record.category) else { continue }
            if let uuid = record.uuid, let match = byUUID[uuid] {
                let incoming = record.modifiedDate ?? .distantPast
                if incoming > match.modifiedDate {
                    record.apply(category: category, to: match)
                }
                continue
            }
            let template = DrinkTemplate(
                name: record.name, category: category, defaultVolumeMl: record.defaultVolumeMl,
                abv: record.abv, icon: record.icon, colorHex: record.colorHex,
                isFavorite: record.isFavorite, isArchived: record.isArchived
            )
            if let uuid = record.uuid { template.uuid = uuid }
            template.modifiedDate = record.modifiedDate ?? .now
            context.insert(template)
            byUUID[template.uuid] = template
        }
    }

    @MainActor
    private func upsertProfile(_ record: ProfileRecord, into context: ModelContext) {
        if let profile = UserProfileStore.deduplicated(in: context) {
            record.apply(to: profile)
        } else {
            let profile = UserProfile()
            record.apply(to: profile)
            context.insert(profile)
        }
    }
}
