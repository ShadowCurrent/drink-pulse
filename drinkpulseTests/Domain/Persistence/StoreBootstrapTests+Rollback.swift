import Testing
import Foundation
@testable import drinkpulse

/// Pins the guarantee documented on `StoreBootstrap.rollBack`: when the move-aside fails,
/// nothing is deleted and each store file is either at the live path or in the snapshot. A
/// complete rollback leaves everything at the live path. An incomplete one moves every store
/// file still at the live path into the snapshot, so the live path keeps only files whose own
/// move into the snapshot failed.
extension StoreBootstrapTests {

    private enum Failure: Error { case move, restore, compensate }

    /// Main file, WAL and -shm at a temp live path, plus a private recovery root. Cleans up
    /// after itself when `cleanUp()` runs from the test's `defer`.
    private struct Fixture {
        let main: URL
        let wal: URL
        let shm: URL
        let recoveryRoot: URL
        var live: [URL] { [main, wal, shm] }

        func cleanUp() {
            let fm = FileManager.default
            for file in live { try? fm.removeItem(at: file) }
            try? fm.removeItem(at: recoveryRoot)
        }

        /// The only snapshot folder `recoverStore` created.
        func snapshot() throws -> URL {
            let names = try FileManager.default.contentsOfDirectory(atPath: recoveryRoot.path)
            #expect(names.count == 1)
            return recoveryRoot.appendingPathComponent(try #require(names.first), isDirectory: true)
        }

        func existsAtLivePath(_ file: URL) -> Bool {
            FileManager.default.fileExists(atPath: file.path)
        }

        func existsInSnapshot(_ file: URL) throws -> Bool {
            let target = try snapshot().appendingPathComponent(file.lastPathComponent)
            return FileManager.default.fileExists(atPath: target.path)
        }
    }

    private func makeFixture() throws -> Fixture {
        let main = makeTempStoreURL()
        let fixture = Fixture(
            main: main,
            wal: URL(fileURLWithPath: main.path + "-wal"),
            shm: URL(fileURLWithPath: main.path + "-shm"),
            recoveryRoot: makeTempRecoveryRoot()
        )
        for file in fixture.live {
            try "data".write(to: file, atomically: true, encoding: .utf8)
        }
        return fixture
    }

    // MARK: - Complete rollback

    @Test func recoverStore_rollsBackEveryFile_whenALaterMoveFails() throws {
        let fixture = try makeFixture()
        let fm = FileManager.default
        // An immutable file cannot be renamed, so the move of -shm fails after the main file
        // and the WAL have already been moved.
        try fm.setAttributes([.immutable: true], ofItemAtPath: fixture.shm.path)
        defer {
            try? fm.setAttributes([.immutable: false], ofItemAtPath: fixture.shm.path)
            fixture.cleanUp()
        }

        #expect(throws: (any Error).self) {
            try StoreBootstrap.recoverStore(at: fixture.main, recoveryRoot: fixture.recoveryRoot)
        }

        for file in fixture.live { #expect(fixture.existsAtLivePath(file)) }
        #expect(try fm.contentsOfDirectory(atPath: fixture.recoveryRoot.path).isEmpty)
    }

    @Test func recoverStore_restoresMainFile_whenTheWalMoveFails() throws {
        let fixture = try makeFixture()
        defer { fixture.cleanUp() }

        #expect(throws: Failure.move) {
            try StoreBootstrap.recoverStore(at: fixture.main, recoveryRoot: fixture.recoveryRoot) { from, to in
                if from.path == fixture.wal.path { throw Failure.move }
                try FileManager.default.moveItem(at: from, to: to)
            }
        }

        for file in fixture.live { #expect(fixture.existsAtLivePath(file)) }
        #expect(try FileManager.default.contentsOfDirectory(atPath: fixture.recoveryRoot.path).isEmpty)
    }

    // MARK: - Incomplete rollback: the snapshot takes every file that can be moved

    @Test func recoverStore_movesWalAndShmIntoSnapshot_whenTheWalMoveFailsOnceAndMainRestoreFails() throws {
        let fixture = try makeFixture()
        defer { fixture.cleanUp() }
        var walMoveAttempts = 0

        // The WAL move fails once, then restoring the main file fails. Left alone, the WAL would
        // sit at the live path with no main file, so the sweep moves it and the -shm into the
        // snapshot with the main file.
        #expect(throws: Failure.move) {
            try StoreBootstrap.recoverStore(at: fixture.main, recoveryRoot: fixture.recoveryRoot) { from, to in
                if from.path == fixture.wal.path {
                    walMoveAttempts += 1
                    if walMoveAttempts == 1 { throw Failure.move }
                }
                if to.path == fixture.main.path { throw Failure.restore }
                try FileManager.default.moveItem(at: from, to: to)
            }
        }

        for file in fixture.live {
            #expect(!fixture.existsAtLivePath(file))
            #expect(try fixture.existsInSnapshot(file))
        }
    }

    @Test func recoverStore_leavesOnlyTheImmovableWalAtLivePath_whenTheWalNeverMovesAndMainRestoreFails() throws {
        let fixture = try makeFixture()
        defer { fixture.cleanUp() }

        // The WAL cannot be moved at all, so no rollback can take it off the live path. Every
        // other file is in the snapshot: the live path holds exactly the file that cannot move.
        #expect(throws: Failure.move) {
            try StoreBootstrap.recoverStore(at: fixture.main, recoveryRoot: fixture.recoveryRoot) { from, to in
                if from.path == fixture.wal.path { throw Failure.move }
                if to.path == fixture.main.path { throw Failure.restore }
                try FileManager.default.moveItem(at: from, to: to)
            }
        }

        #expect(fixture.existsAtLivePath(fixture.wal))
        #expect(!fixture.existsAtLivePath(fixture.main))
        #expect(!fixture.existsAtLivePath(fixture.shm))
        #expect(try fixture.existsInSnapshot(fixture.main))
        #expect(try fixture.existsInSnapshot(fixture.shm))
    }

    @Test func recoverStore_keepsMainFileAndWalInSnapshot_whenWalRestoreFails() throws {
        let fixture = try makeFixture()
        defer { fixture.cleanUp() }

        // The -shm move fails, then restoring the WAL fails. The rollback stops there, and the
        // immovable -shm is the only file left at the live path.
        #expect(throws: Failure.move) {
            try StoreBootstrap.recoverStore(at: fixture.main, recoveryRoot: fixture.recoveryRoot) { from, to in
                if from.path == fixture.shm.path { throw Failure.move }
                if to.path == fixture.wal.path { throw Failure.restore }
                try FileManager.default.moveItem(at: from, to: to)
            }
        }

        #expect(try fixture.existsInSnapshot(fixture.main))
        #expect(try fixture.existsInSnapshot(fixture.wal))
        #expect(!fixture.existsAtLivePath(fixture.main))
        #expect(!fixture.existsAtLivePath(fixture.wal))
        #expect(fixture.existsAtLivePath(fixture.shm))
    }

    @Test func recoverStore_returnsRestoredWalToSnapshot_whenMainFileRestoreFailsAfterWalRestore() throws {
        let fixture = try makeFixture()
        defer { fixture.cleanUp() }

        // The -shm move fails, the WAL restore succeeds, then restoring the main file fails. The
        // restored WAL has no main file at the live path, so the sweep moves it back.
        #expect(throws: Failure.move) {
            try StoreBootstrap.recoverStore(at: fixture.main, recoveryRoot: fixture.recoveryRoot) { from, to in
                if from.path == fixture.shm.path { throw Failure.move }
                if to.path == fixture.main.path { throw Failure.restore }
                try FileManager.default.moveItem(at: from, to: to)
            }
        }

        #expect(try fixture.existsInSnapshot(fixture.main))
        #expect(try fixture.existsInSnapshot(fixture.wal))
        #expect(!fixture.existsAtLivePath(fixture.main))
        #expect(!fixture.existsAtLivePath(fixture.wal))
        #expect(fixture.existsAtLivePath(fixture.shm))
    }

    @Test func recoverStore_rethrowsOriginalErrorAndKeepsSnapshot_whenTheSweepMoveAlsoFails() throws {
        let fixture = try makeFixture()
        defer { fixture.cleanUp() }

        // Same failure as above, but returning the restored WAL to the snapshot fails too. The
        // original error still surfaces, the snapshot folder is kept with the main file, and the
        // WAL and -shm, whose moves failed, are the only files at the live path.
        var walMoveAttempts = 0
        #expect(throws: Failure.move) {
            try StoreBootstrap.recoverStore(at: fixture.main, recoveryRoot: fixture.recoveryRoot) { from, to in
                if from.path == fixture.shm.path { throw Failure.move }
                if to.path == fixture.main.path { throw Failure.restore }
                if from.path == fixture.wal.path {
                    walMoveAttempts += 1
                    // The first attempt is the forward move; the second is the sweep.
                    if walMoveAttempts == 2 { throw Failure.compensate }
                }
                try FileManager.default.moveItem(at: from, to: to)
            }
        }

        #expect(try fixture.existsInSnapshot(fixture.main))
        #expect(fixture.existsAtLivePath(fixture.wal))
        #expect(fixture.existsAtLivePath(fixture.shm))
        #expect(!fixture.existsAtLivePath(fixture.main))
    }
}
