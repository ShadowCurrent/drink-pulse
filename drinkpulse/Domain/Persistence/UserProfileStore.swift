import Foundation
import SwiftData
import OSLog

private nonisolated let log = Logger(subsystem: "com.drinkpulse.app", category: "persistence")

enum UserProfileStore {

    @MainActor
    static func fetchOrCreate(in context: ModelContext) -> UserProfile {
        if let profile = deduplicated(in: context) {
            try? context.save()
            return profile
        }
        let profile = UserProfile()
        context.insert(profile)
        try? context.save()
        return profile
    }

    @MainActor
    @discardableResult
    static func deduplicated(in context: ModelContext) -> UserProfile? {
        let profiles = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        guard let survivor = profiles.max(by: { $0.modifiedDate < $1.modifiedDate }) else {
            return nil
        }
        for duplicate in profiles where duplicate !== survivor {
            context.delete(duplicate)
        }
        if profiles.count > 1 {
            log.info("UserProfileStore collapsed \(profiles.count, privacy: .public) profiles to 1")
        }
        return survivor
    }
}
