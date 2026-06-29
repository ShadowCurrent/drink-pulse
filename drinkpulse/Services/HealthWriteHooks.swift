import SwiftData
import SwiftUI

/// Bridges the in-app mutation sites (Add / Edit / Delete) to the optional
/// `HealthService`, so each site fires the matching Health op **only when the
/// user enabled write-back** (plan-0036, W5).
///
/// Every call is **best-effort and non-blocking**: the gate is a cheap
/// `UserDefaults` read, the Health op runs in a detached `Task`, and a Health
/// failure can never block or revert the in-app mutation (the SwiftData store is
/// the source of truth). The service mutates `event.healthKitUUID` (a device-local
/// cache) but owns no `ModelContext`, so the write/update hooks save the context
/// inside the task to persist the freshly-stamped UUID.
@MainActor
enum HealthWriteHooks {
    /// Whether Apple Health write-back is enabled. Off by default — an unset key
    /// reads as `false`, matching `@AppStorage(...) = false` in the Settings UI.
    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: AppStorageKeys.healthWriteEnabled)
    }

    /// After an event is inserted + the in-app log committed, mirror it to Health
    /// and persist the stamped `healthKitUUID`. No-op when disabled or no service.
    static func write(_ event: ConsumptionEvent, in context: ModelContext, using service: HealthService?) {
        guard isEnabled, let service else { return }
        Task {
            await service.write(event)
            // Persist the device-local healthKitUUID the service stamped in place.
            try? context.save()
        }
    }

    /// After an edit is saved in-app, rewrite the Health sample and persist the
    /// re-stamped `healthKitUUID`. No-op when disabled or no service.
    static func update(_ event: ConsumptionEvent, in context: ModelContext, using service: HealthService?) {
        guard isEnabled, let service else { return }
        Task {
            await service.update(event)
            try? context.save()
        }
    }

    /// Remove the Health sample for an event being deleted. **Call this BEFORE
    /// `context.delete(event)`**: the event's identifiers are captured here,
    /// synchronously, so the detached task can delete the right sample even though
    /// the `@Model` is invalidated by the time it runs. No-op when disabled.
    static func remove(_ event: ConsumptionEvent, using service: HealthService?) {
        guard isEnabled, let service else { return }
        let healthKitUUID = event.healthKitUUID
        let eventUUID = event.uuid
        Task {
            await service.removeSample(healthKitUUID: healthKitUUID, eventUUID: eventUUID)
        }
    }
}
