import Foundation
import SwiftData
import OSLog

private nonisolated let dedupeLog = Logger(subsystem: "com.drinkpulse.app", category: "persistence")

/// A syncable record with a stable identity and an LWW clock (plan-0023).
/// `uuid` is the app-level identity (NOT the CloudKit record id), so the same
/// logical record can arrive twice via sync or a backup restore.
protocol IdentifiedRecord: PersistentModel {
    var uuid: UUID { get set }
    var modifiedDate: Date { get }
}

extension ConsumptionEvent: IdentifiedRecord {}
extension DrinkTemplate: IdentifiedRecord {}

/// Cross-device de-dup (plan-0023). CloudKit cannot enforce uniqueness on the
/// app-level `uuid`, so two objects that share a `uuid` (synced twice, or a
/// backup re-imported on another device) must be collapsed in code. Newer-wins:
/// the row with the newest `modifiedDate` survives, the rest are deleted.
///
/// Run on launch (Phase A) and after each CloudKit sync (Phase B). Also enforces
/// a distinct `uuid` at insert time as a belt-and-suspenders guard.
enum RecordDeduplicator {

    /// Collapses duplicate events, templates, and profiles to one survivor each.
    @MainActor
    static func sweep(in context: ModelContext) {
        dedupe(ConsumptionEvent.self, in: context)
        dedupe(DrinkTemplate.self, in: context)
        UserProfileStore.deduplicated(in: context)
    }

    /// Groups `T` by `uuid`, keeps the newest `modifiedDate`, deletes the rest.
    @MainActor
    static func dedupe<T: IdentifiedRecord>(_ type: T.Type, in context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<T>())) ?? []
        var survivors: [UUID: T] = [:]
        var deleted = 0
        for record in all {
            if let current = survivors[record.uuid] {
                // Keep whichever is newer; delete the loser.
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

    /// Belt-and-suspenders: guarantees `record` carries a `uuid` not already used
    /// by another row, regenerating on the (astronomically unlikely) collision.
    /// Call right after inserting a freshly created record.
    @MainActor
    static func ensureUniqueIdentity<T: IdentifiedRecord>(_ record: T, in context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<T>())) ?? []
        while all.contains(where: { $0 !== record && $0.uuid == record.uuid }) {
            record.uuid = UUID()
        }
    }
}
