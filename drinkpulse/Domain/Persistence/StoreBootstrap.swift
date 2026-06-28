import Foundation
import SwiftData
import OSLog

private nonisolated let log = Logger(subsystem: "com.drinkpulse.app", category: "persistence")

struct StoreBootstrap {

    // Maximum number of recovered-store snapshots to retain.
    nonisolated static let maxRecoveredStores = 3

    /// Opens (or recovers) the SwiftData container for the given schema and configuration.
    ///
    /// Must be called on the main actor because `ModelContainer.init` is main-actor-isolated.
    /// If the container fails to open, the existing store files are moved to a timestamped
    /// subfolder in Application Support (never deleted) and a fresh container is created.
    @MainActor
    static func makeContainer(
        schema: Schema,
        configuration: ModelConfiguration
    ) throws -> ModelContainer {
        do {
            return try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: [configuration])
        } catch {
            log.error("Store open failed — attempting non-destructive recovery")
            try recoverStore(at: configuration.url)
            let container = try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: [configuration])
            log.info("Recovery complete — fresh container is open")
            return container
        }
    }

    // MARK: - Internal (nonisolated — FileManager only)

    /// Moves store files (.sqlite / .sqlite-wal / .sqlite-shm) to a timestamped
    /// RecoveredStores/ folder inside Application Support. Trims oldest snapshots
    /// when count exceeds `maxRecoveredStores`.
    nonisolated static func recoverStore(at storeURL: URL) throws {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let recoveryRoot = appSupport.appendingPathComponent("RecoveredStores", isDirectory: true)
        try fm.createDirectory(at: recoveryRoot, withIntermediateDirectories: true)

        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let destination = recoveryRoot.appendingPathComponent(timestamp, isDirectory: true)
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)

        let suffixes = ["", "-wal", "-shm"]
        for suffix in suffixes {
            let source = storeURL.deletingPathExtension()
                .appendingPathExtension(storeURL.pathExtension + suffix)
            if fm.fileExists(atPath: source.path) {
                let target = destination.appendingPathComponent(source.lastPathComponent)
                try fm.moveItem(at: source, to: target)
            }
        }

        log.error("Store files moved to RecoveredStores snapshot — category: recovery")
        trimRecoveredStores(in: recoveryRoot)
    }

    /// Removes the RecoveredStores folder entirely (called from "Delete all data").
    nonisolated static func clearRecoveredStores() {
        guard let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else { return }
        let root = appSupport.appendingPathComponent("RecoveredStores", isDirectory: true)
        try? FileManager.default.removeItem(at: root)
    }

    // MARK: - Private

    /// Removes oldest timestamped snapshots beyond `maxRecoveredStores`.
    nonisolated private static func trimRecoveredStores(in root: URL) {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }
        let sorted = entries.sorted { a, b in
            let dateA = (try? a.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let dateB = (try? b.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            return dateA < dateB
        }
        if sorted.count > maxRecoveredStores {
            for old in sorted.dropLast(maxRecoveredStores) {
                try? fm.removeItem(at: old)
            }
        }
    }
}
