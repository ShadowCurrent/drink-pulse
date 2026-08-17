import SwiftData
import SwiftUI

@MainActor
enum HealthWriteHooks {
    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: AppStorageKeys.healthWriteEnabled)
    }

    @discardableResult
    static func write(_ event: ConsumptionEvent, in context: ModelContext, using service: HealthService?) -> Task<Void, Never>? {
        guard isEnabled, let service else { return nil }
        return Task {
            await service.write(event)
            try? context.save()
        }
    }

    @discardableResult
    static func update(_ event: ConsumptionEvent, in context: ModelContext, using service: HealthService?) -> Task<Void, Never>? {
        guard isEnabled, let service else { return nil }
        return Task {
            await service.update(event)
            try? context.save()
        }
    }

    @discardableResult
    static func remove(_ event: ConsumptionEvent, using service: HealthService?) -> Task<Void, Never>? {
        guard isEnabled, let service else { return nil }
        let healthKitUUID = event.healthKitUUID
        let eventUUID = event.uuid
        return Task {
            await service.removeSample(healthKitUUID: healthKitUUID, eventUUID: eventUUID)
        }
    }
}
