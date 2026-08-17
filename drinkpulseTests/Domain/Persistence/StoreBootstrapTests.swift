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
        let schema = Schema([ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self])
        let config = ModelConfiguration(schema: schema, url: url)
        let fm = FileManager.default

        _ = try StoreBootstrap.makeContainer(schema: schema, configuration: config)
        #expect(fm.fileExists(atPath: url.path))

        try fm.setAttributes([.posixPermissions: 0o000], ofItemAtPath: url.path)

        defer {
            try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
        }

        let recovered = try StoreBootstrap.makeContainer(schema: schema, configuration: config)
        _ = recovered.mainContext
    }

    // MARK: - Recovery: original files are NOT deleted

    @Test func recoverStore_movesFilesNotDeletes() throws {
        let url = makeTempStoreURL()
        let fm = FileManager.default

        try "fake store data".write(to: url, atomically: true, encoding: .utf8)
        #expect(fm.fileExists(atPath: url.path))

        try StoreBootstrap.recoverStore(at: url)

        #expect(!fm.fileExists(atPath: url.path))
    }

    @Test func recoverStore_filesArePresentInRecoveredFolder() throws {
        let url = makeTempStoreURL()
        let fm = FileManager.default

        try "fake store data".write(to: url, atomically: true, encoding: .utf8)
        try StoreBootstrap.recoverStore(at: url)

        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            Issue.record("No Application Support directory")
            return
        }
        let recoveryRoot = appSupport.appendingPathComponent("RecoveredStores")
        let contents = try fm.contentsOfDirectory(atPath: recoveryRoot.path)
        #expect(!contents.isEmpty)
    }

    // MARK: - Trimming

    @Test func recoverStore_keepsAtMostMaxSnapshots() throws {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            Issue.record("No Application Support directory")
            return
        }
        let recoveryRoot = appSupport.appendingPathComponent("RecoveredStores")

        let overLimit = StoreBootstrap.maxRecoveredStores + 2
        for i in 0..<overLimit {
            let snapDir = recoveryRoot
                .appendingPathComponent("2020-01-0\(i)T00-00-00Z", isDirectory: true)
            try fm.createDirectory(at: snapDir, withIntermediateDirectories: true)
            try "x".write(to: snapDir.appendingPathComponent("store.sqlite"),
                          atomically: true, encoding: .utf8)
            Thread.sleep(forTimeInterval: 0.01)
        }

        let url = makeTempStoreURL()
        try "fake".write(to: url, atomically: true, encoding: .utf8)
        try StoreBootstrap.recoverStore(at: url)

        let afterContents = try fm.contentsOfDirectory(atPath: recoveryRoot.path)
        #expect(afterContents.count <= StoreBootstrap.maxRecoveredStores)
    }

    // MARK: - Clear

    @Test func clearRecoveredStores_removesFolder() throws {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            Issue.record("No Application Support directory")
            return
        }
        let recoveryRoot = appSupport.appendingPathComponent("RecoveredStores")
        try fm.createDirectory(at: recoveryRoot, withIntermediateDirectories: true)
        try "x".write(to: recoveryRoot.appendingPathComponent("dummy.txt"),
                      atomically: true, encoding: .utf8)

        StoreBootstrap.clearRecoveredStores()
        #expect(!fm.fileExists(atPath: recoveryRoot.path))
    }
}
