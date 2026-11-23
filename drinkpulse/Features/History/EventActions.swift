import SwiftUI
import SwiftData
import OSLog

/// Log Again and Delete for a stored event, shared by the History row actions and Edit Drink
/// (plan 0047). Views stay the only callers that mutate through `modelContext` (ADR-0004).
@MainActor
enum EventActions {
    private static let logger = Logger(subsystem: "com.drinkpulse.app", category: "EventActions")

    /// Logs a copy of the stored event now and writes it to Apple Health like any new drink
    /// (D0047-10). The copy carries no `healthKitUUID`, so Health gets a fresh sample.
    static func logAgain(
        _ event: ConsumptionEvent,
        in context: ModelContext,
        healthService: HealthService?,
        reduceMotion: Bool,
        drinkLogged: DrinkLoggedAction
    ) {
        let copy = event.duplicated()
        withMotion(reduceMotion: reduceMotion) {
            context.insert(copy)
            RecordDeduplicator.ensureUniqueIdentity(copy, in: context)
            do {
                try context.save()
            } catch {
                logger.error("Log Again save failed: \(String(describing: type(of: error)))")
            }
        }
        HealthWriteHooks.write(copy, in: context, using: healthService)
        drinkLogged(copy)
    }

    /// Deletes the event and always removes its Apple Health sample (plan 0036).
    static func delete(
        _ event: ConsumptionEvent,
        in context: ModelContext,
        healthService: HealthService?,
        reduceMotion: Bool
    ) {
        withMotion(reduceMotion: reduceMotion) {
            HealthWriteHooks.remove(event, using: healthService)
            context.delete(event)
            do {
                try context.save()
            } catch {
                logger.error("Delete save failed: \(String(describing: type(of: error)))")
            }
        }
    }
}
