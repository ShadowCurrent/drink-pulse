import Foundation
import SwiftData
import OSLog

private nonisolated let log = Logger(subsystem: "com.drinkpulse.app", category: "persistence")

struct StoreBootstrap {

    nonisolated static let maxRecoveredStores = 3

    enum RecoveryError: Error {
        /// The Application Support directory could not be resolved, so no snapshot location exists.
        case recoveryLocationUnavailable
    }

    nonisolated static let cloudKitContainerID = "iCloud.com.drinkpulse.app"

    @MainActor
    static func productionConfiguration(schema: Schema) -> ModelConfiguration {
        ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    }

    @MainActor
    static func makeContainer(
        schema: Schema,
        configuration: ModelConfiguration
    ) throws -> ModelContainer {
        try makeContainerReportingRecovery(schema: schema, configuration: configuration).container
    }

    /// Same open-and-recover flow as `makeContainer`, but also reports whether the
    /// non-destructive recovery branch ran. Migration tests use it so a silent
    /// move-aside can never pass as a successful migration.
    ///
    /// `recoveryRoot` defaults to `Application Support/RecoveredStores`; tests inject a temp
    /// directory so recovery never touches the real snapshot folder.
    @MainActor
    static func makeContainerReportingRecovery(
        schema: Schema,
        configuration: ModelConfiguration,
        recoveryRoot: URL? = nil
    ) throws -> (container: ModelContainer, didRecover: Bool) {
        do {
            let container = try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: [configuration])
            return (container, false)
        } catch {
            // Domain and code are error categories, not user data. Logged before recovery so a
            // recovery failure cannot hide the root cause.
            let openError = error as NSError
            log.error("Store open failed — attempting non-destructive recovery; domain: \(openError.domain, privacy: .public), code: \(openError.code, privacy: .public)")
            try recoverStore(at: configuration.url, recoveryRoot: recoveryRoot)
            let container = try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: [configuration])
            log.info("Recovery complete — fresh container is open")
            return (container, true)
        }
    }

    // MARK: - Internal (nonisolated — FileManager only)

    nonisolated static func defaultRecoveryRoot() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("RecoveredStores", isDirectory: true)
    }

    /// `moveItem` defaults to `FileManager.moveItem(at:to:)`; tests inject a failing mover to
    /// exercise the rollback paths, which cannot be reproduced reliably with real file permissions.
    nonisolated static func recoverStore(
        at storeURL: URL,
        recoveryRoot: URL? = nil,
        moveItem: (URL, URL) throws -> Void = { try FileManager.default.moveItem(at: $0, to: $1) }
    ) throws {
        let fm = FileManager.default
        guard let recoveryRoot = recoveryRoot ?? defaultRecoveryRoot() else {
            throw RecoveryError.recoveryLocationUnavailable
        }
        try fm.createDirectory(at: recoveryRoot, withIntermediateDirectories: true)

        // Second-resolution timestamps alone collide when two recoveries land in the same
        // second, so every snapshot gets a short random suffix as well.
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let destination = recoveryRoot.appendingPathComponent(
            "\(timestamp)-\(UUID().uuidString.prefix(8))", isDirectory: true
        )
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)

        // All-or-nothing: a main file without its WAL in the snapshot (or a WAL left behind
        // next to a fresh store) is worse than no move, so a failure puts every file back.
        var moved: [(from: URL, to: URL)] = []
        do {
            for suffix in ["", "-wal", "-shm"] {
                let source = storeURL.deletingPathExtension()
                    .appendingPathExtension(storeURL.pathExtension + suffix)
                guard fm.fileExists(atPath: source.path) else { continue }
                let target = destination.appendingPathComponent(source.lastPathComponent)
                try moveItem(source, target)
                moved.append((from: source, to: target))
            }
        } catch {
            var rolledBack = true
            for entry in moved.reversed() {
                do {
                    try moveItem(entry.to, entry.from)
                } catch {
                    rolledBack = false
                }
            }
            // Remove the empty snapshot folder only after a complete rollback, so a failed
            // rollback never deletes the files it could not restore.
            if rolledBack {
                try? fm.removeItem(at: destination)
            }
            log.error("Store move-aside failed — category: recovery, rolled back: \(rolledBack, privacy: .public)")
            throw error
        }

        log.error("Store files moved to RecoveredStores snapshot — category: recovery")
        trimRecoveredStores(in: recoveryRoot)
    }

    nonisolated static func clearRecoveredStores(root: URL? = nil) {
        guard let root = root ?? defaultRecoveryRoot() else { return }
        try? FileManager.default.removeItem(at: root)
    }

    // MARK: - Private

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
