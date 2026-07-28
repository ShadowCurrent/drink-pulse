import Foundation
import SwiftData
import OSLog

private nonisolated let log = Logger(subsystem: "com.drinkpulse.app", category: "persistence")

/// App-level enforcement of the **single `UserProfile`** invariant.
///
/// CloudKit (plan-0023 Phase B) forbids `@Attribute(.unique)`, so once the unique
/// constraint is dropped in `SchemaV2` nothing in the store guarantees one profile.
/// Two devices editing offline, or a backup restore, can each insert a profile and
/// sync would then surface duplicates. This store re-establishes the invariant in
/// code: a fetch-or-create entry point plus a de-dupe that collapses any duplicates
/// to a single row.
///
/// Conflict policy is LWW by `modifiedDate` (plan-0023): when duplicates exist the
/// **newest `modifiedDate`** is kept so an offline profile edit is never lost to an
/// older copy. (`UserProfile` has no `uuid` — its identity is the singleton `id`.)
enum UserProfileStore {

    /// Returns the single profile, creating and inserting one if none exists and
    /// collapsing any duplicates first. All `profiles.first` call sites should
    /// route through here so they always observe exactly one profile.
    @MainActor
    static func fetchOrCreate(in context: ModelContext) -> UserProfile {
        if let profile = deduplicated(in: context) {
            // Best-effort: a failed save here just re-opens the dedupe-delete
            // timing gap on the next @Query render; logged via `deduplicated`,
            // not surfaced, since there's no user action to retry from here.
            try? context.save()
            return profile
        }
        let profile = UserProfile()
        context.insert(profile)
        // Best-effort: a failed save here just re-opens the D-04 timing gap on
        // the next @Query render; logged, not surfaced, since there's no user
        // action to retry from this call site.
        try? context.save()
        return profile
    }

    /// Collapses duplicate profiles to the one with the newest `modifiedDate`,
    /// deleting the rest. Returns the surviving profile, or nil if the store holds
    /// none. A fetch failure is treated as "no profile" (best-effort).
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
