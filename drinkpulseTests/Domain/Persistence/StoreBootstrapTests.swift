import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct StoreBootstrapTests {

    private func makeTempStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
    }

    /// A private recovery root per test, so tests never share (or pollute) the real
    /// `Application Support/RecoveredStores` folder and cannot race each other.
    private func makeTempRecoveryRoot() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("RecoveredStores-\(UUID().uuidString)", isDirectory: true)
    }

    // MARK: - Happy path

    @Test func makeContainer_opensCleanStore() throws {
        let url = makeTempStoreURL()
        let schema = Schema([ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self])
        let config = ModelConfiguration(schema: schema, url: url)

        let container = try StoreBootstrap.makeContainer(schema: schema, configuration: config)
        _ = container.mainContext
    }

    // MARK: - Recovery path

    @Test func makeContainer_unreadableStore_recoversAndReturnsFreshContainer() throws {
        let url = makeTempStoreURL()
        let recoveryRoot = makeTempRecoveryRoot()
        let schema = Schema([ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self])
        let config = ModelConfiguration(schema: schema, url: url)
        let fm = FileManager.default

        _ = try StoreBootstrap.makeContainer(schema: schema, configuration: config)
        #expect(fm.fileExists(atPath: url.path))

        try fm.setAttributes([.posixPermissions: 0o000], ofItemAtPath: url.path)

        defer {
            try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
            try? fm.removeItem(at: recoveryRoot)
        }

        let recovered = try StoreBootstrap.makeContainerReportingRecovery(
            schema: schema, configuration: config, recoveryRoot: recoveryRoot
        )
        #expect(recovered.didRecover)
        _ = recovered.container.mainContext
    }

    // MARK: - Recovery: original files are NOT deleted

    @Test func recoverStore_movesFilesNotDeletes() throws {
        let url = makeTempStoreURL()
        let recoveryRoot = makeTempRecoveryRoot()
        let fm = FileManager.default
        defer { try? fm.removeItem(at: recoveryRoot) }

        try "fake store data".write(to: url, atomically: true, encoding: .utf8)
        #expect(fm.fileExists(atPath: url.path))

        try StoreBootstrap.recoverStore(at: url, recoveryRoot: recoveryRoot)

        #expect(!fm.fileExists(atPath: url.path))
    }

    @Test func recoverStore_filesArePresentInRecoveredFolder() throws {
        let url = makeTempStoreURL()
        let recoveryRoot = makeTempRecoveryRoot()
        let fm = FileManager.default
        defer { try? fm.removeItem(at: recoveryRoot) }

        try "fake store data".write(to: url, atomically: true, encoding: .utf8)
        try StoreBootstrap.recoverStore(at: url, recoveryRoot: recoveryRoot)

        let snapshots = try fm.contentsOfDirectory(atPath: recoveryRoot.path)
        #expect(snapshots.count == 1)
        let snapshot = recoveryRoot.appendingPathComponent(try #require(snapshots.first))
        #expect(fm.fileExists(atPath: snapshot.appendingPathComponent(url.lastPathComponent).path))
    }

    @Test func recoverStore_twoRecoveriesInTheSameSecond_keepSeparateSnapshots() throws {
        let url = makeTempStoreURL()
        let recoveryRoot = makeTempRecoveryRoot()
        let fm = FileManager.default
        defer { try? fm.removeItem(at: recoveryRoot) }

        try "first".write(to: url, atomically: true, encoding: .utf8)
        try StoreBootstrap.recoverStore(at: url, recoveryRoot: recoveryRoot)
        try "second".write(to: url, atomically: true, encoding: .utf8)
        try StoreBootstrap.recoverStore(at: url, recoveryRoot: recoveryRoot)

        #expect(try fm.contentsOfDirectory(atPath: recoveryRoot.path).count == 2)
        #expect(!fm.fileExists(atPath: url.path))
    }

    @Test func recoverStore_rollsBackEveryFile_whenALaterMoveFails() throws {
        let url = makeTempStoreURL()
        let recoveryRoot = makeTempRecoveryRoot()
        let fm = FileManager.default
        let wal = URL(fileURLWithPath: url.path + "-wal")
        let shm = URL(fileURLWithPath: url.path + "-shm")
        for file in [url, wal, shm] {
            try "data".write(to: file, atomically: true, encoding: .utf8)
        }
        // An immutable file cannot be renamed, so the move of -shm fails after the main file
        // and the WAL have already been moved.
        try fm.setAttributes([.immutable: true], ofItemAtPath: shm.path)
        defer {
            try? fm.setAttributes([.immutable: false], ofItemAtPath: shm.path)
            for file in [url, wal, shm] { try? fm.removeItem(at: file) }
            try? fm.removeItem(at: recoveryRoot)
        }

        #expect(throws: (any Error).self) {
            try StoreBootstrap.recoverStore(at: url, recoveryRoot: recoveryRoot)
        }

        #expect(fm.fileExists(atPath: url.path))
        #expect(fm.fileExists(atPath: wal.path))
        #expect(fm.fileExists(atPath: shm.path))
        #expect(try fm.contentsOfDirectory(atPath: recoveryRoot.path).isEmpty)
    }

    @Test func recoverStore_keepsMainFileAndWalTogetherInSnapshot_whenARollbackMoveAlsoFails() throws {
        struct MoveFailure: Error {}
        let url = makeTempStoreURL()
        let recoveryRoot = makeTempRecoveryRoot()
        let fm = FileManager.default
        let wal = URL(fileURLWithPath: url.path + "-wal")
        let shm = URL(fileURLWithPath: url.path + "-shm")
        for file in [url, wal, shm] {
            try "data".write(to: file, atomically: true, encoding: .utf8)
        }
        defer {
            for file in [url, wal, shm] { try? fm.removeItem(at: file) }
            try? fm.removeItem(at: recoveryRoot)
        }

        // The -shm move fails, then restoring the WAL fails too. The rollback stops there, so the
        // main file stays in the snapshot with the WAL and no main file or WAL stays at the live path.
        #expect(throws: MoveFailure.self) {
            try StoreBootstrap.recoverStore(at: url, recoveryRoot: recoveryRoot) { from, to in
                if from.lastPathComponent.hasSuffix("-shm") || to.path == wal.path {
                    throw MoveFailure()
                }
                try fm.moveItem(at: from, to: to)
            }
        }

        let snapshots = try fm.contentsOfDirectory(atPath: recoveryRoot.path)
        #expect(snapshots.count == 1)
        let snapshot = recoveryRoot.appendingPathComponent(try #require(snapshots.first))
        #expect(fm.fileExists(atPath: snapshot.appendingPathComponent(url.lastPathComponent).path))
        #expect(fm.fileExists(atPath: snapshot.appendingPathComponent(wal.lastPathComponent).path))
        #expect(!fm.fileExists(atPath: url.path))
        #expect(!fm.fileExists(atPath: wal.path))
    }

    @Test func recoverStore_leavesNoMainFileOrWalAtLivePath_whenMainFileRestoreFailsAfterWalRestore() throws {
        struct MoveFailure: Error {}
        let url = makeTempStoreURL()
        let recoveryRoot = makeTempRecoveryRoot()
        let fm = FileManager.default
        let wal = URL(fileURLWithPath: url.path + "-wal")
        let shm = URL(fileURLWithPath: url.path + "-shm")
        for file in [url, wal, shm] {
            try "data".write(to: file, atomically: true, encoding: .utf8)
        }
        defer {
            for file in [url, wal, shm] { try? fm.removeItem(at: file) }
            try? fm.removeItem(at: recoveryRoot)
        }

        // The -shm move fails, the WAL restore succeeds, then restoring the main file fails. A WAL
        // left at the live path with no main file would be replayed against a fresh store, so the
        // rollback must put the restored WAL back. The unmoved -shm stays at the live path, which
        // is harmless because SQLite rebuilds it.
        #expect(throws: MoveFailure.self) {
            try StoreBootstrap.recoverStore(at: url, recoveryRoot: recoveryRoot) { from, to in
                if from.lastPathComponent.hasSuffix("-shm") || to.path == url.path {
                    throw MoveFailure()
                }
                try fm.moveItem(at: from, to: to)
            }
        }

        let snapshots = try fm.contentsOfDirectory(atPath: recoveryRoot.path)
        #expect(snapshots.count == 1)
        let snapshot = recoveryRoot.appendingPathComponent(try #require(snapshots.first))
        #expect(fm.fileExists(atPath: snapshot.appendingPathComponent(url.lastPathComponent).path))
        #expect(fm.fileExists(atPath: snapshot.appendingPathComponent(wal.lastPathComponent).path))
        #expect(!fm.fileExists(atPath: url.path))
        #expect(!fm.fileExists(atPath: wal.path))
        #expect(fm.fileExists(atPath: shm.path))
    }

    // MARK: - Trimming

    @Test func recoverStore_keepsAtMostMaxSnapshots() throws {
        let fm = FileManager.default
        let recoveryRoot = makeTempRecoveryRoot()
        defer { try? fm.removeItem(at: recoveryRoot) }

        let overLimit = StoreBootstrap.maxRecoveredStores + 2
        var seededNames: [String] = []
        for i in 0..<overLimit {
            let name = "2020-01-0\(i)T00-00-00Z"
            seededNames.append(name)
            let snapDir = recoveryRoot.appendingPathComponent(name, isDirectory: true)
            try fm.createDirectory(at: snapDir, withIntermediateDirectories: true)
            try "x".write(to: snapDir.appendingPathComponent("store.sqlite"),
                          atomically: true, encoding: .utf8)
            Thread.sleep(forTimeInterval: 0.01)
        }

        let url = makeTempStoreURL()
        try "fake".write(to: url, atomically: true, encoding: .utf8)
        try StoreBootstrap.recoverStore(at: url, recoveryRoot: recoveryRoot)

        let afterContents = try fm.contentsOfDirectory(atPath: recoveryRoot.path)
        #expect(afterContents.count == StoreBootstrap.maxRecoveredStores)

        // The snapshot just created (the one entry that was not seeded) must survive, and the
        // oldest seeded snapshots are the ones trimmed. Its name is random, so it is found by
        // elimination rather than by name.
        let newSnapshots = afterContents.filter { !seededNames.contains($0) }
        #expect(newSnapshots.count == 1)
        let keptSeeded = Set(afterContents).intersection(seededNames)
        let expectedKept = Set(seededNames.suffix(StoreBootstrap.maxRecoveredStores - 1))
        #expect(keptSeeded == expectedKept)
    }

    // MARK: - Clear

    @Test func clearRecoveredStores_removesFolder() throws {
        let fm = FileManager.default
        let recoveryRoot = makeTempRecoveryRoot()
        try fm.createDirectory(at: recoveryRoot, withIntermediateDirectories: true)
        try "x".write(to: recoveryRoot.appendingPathComponent("dummy.txt"),
                      atomically: true, encoding: .utf8)

        StoreBootstrap.clearRecoveredStores(root: recoveryRoot)
        #expect(!fm.fileExists(atPath: recoveryRoot.path))
    }
}
