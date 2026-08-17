import Foundation
import SwiftData
import OSLog

private nonisolated let dedupeLog = Logger(subsystem: "com.drinkpulse.app", category: "persistence")

protocol IdentifiedRecord: PersistentModel {
    var uuid: UUID { get set }
    var modifiedDate: Date { get }
}

extension ConsumptionEvent: IdentifiedRecord {}
extension DrinkTemplate: IdentifiedRecord {}

enum RecordDeduplicator {

    @MainActor
    static func sweep(in context: ModelContext) {
        dedupe(ConsumptionEvent.self, in: context)
        dedupe(DrinkTemplate.self, in: context)
        UserProfileStore.deduplicated(in: context)
    }

    @MainActor
    static func dedupe<T: IdentifiedRecord>(_ type: T.Type, in context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<T>())) ?? []
        var survivors: [UUID: T] = [:]
        var deleted = 0
        for record in all {
            if let current = survivors[record.uuid] {
                if record.modifiedDate > current.modifiedDate {
                    context.delete(current)
                    survivors[record.uuid] = record
                } else {
                    context.delete(record)
                }
                deleted += 1
            } else {
                survivors[record.uuid] = record
            }
        }
        if deleted > 0 {
            dedupeLog.info("De-dup swept \(deleted, privacy: .public) duplicate \(String(describing: T.self), privacy: .public) rows")
        }
    }

    @MainActor
    static func ensureUniqueIdentity<T: IdentifiedRecord>(_ record: T, in context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<T>())) ?? []
        while all.contains(where: { $0 !== record && $0.uuid == record.uuid }) {
            record.uuid = UUID()
        }
    }
}
