import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct DataBackupExportTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // MARK: - BackupExport (lazy share)

    @Test func backupExport_fileName_containsDate() {
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01
        let name = BackupExport.fileName(for: date)
        #expect(name.hasPrefix("drinkpulse-backup-1970-01-01"))
        #expect(name.hasSuffix(".json"))
    }

    @Test func backupExport_snapshotsRecordsUpFront() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05,
                                     category: .beer, icon: "🍺")
        let profile = UserProfile(bodyWeightKg: 70.0, biologicalSex: .male,
                                   guidelineChoice: .who, weeklyGoalGrams: 100.0,
                                   unitSystem: .metric, currency: "USD")
        let export = BackupExport(events: [event], profile: profile)
        #expect(export.events.count == 1)
        #expect(export.profile != nil)
    }

    @Test func backupExport_encoded_producesDecodableBundle() throws {
        let event = ConsumptionEvent(volumeMl: 355, abv: 0.05,
                                     category: .beer, icon: "🍺")
        let profile = UserProfile(bodyWeightKg: 70.0, biologicalSex: .male,
                                   guidelineChoice: .who, weeklyGoalGrams: 100.0,
                                   unitSystem: .metric, currency: "USD")
        let data = try BackupExport(events: [event], profile: profile).encoded()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bundle = try decoder.decode(ExportBundle.self, from: data)
        #expect(bundle.version == 2)
        #expect(bundle.events.count == 1)
        #expect(bundle.profile != nil)
    }

    @Test func backupExport_writeTempFile_createsReadableFile() throws {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05,
                                     category: .beer, icon: "🍺")
        let url = try BackupExport(events: [event], profile: nil).writeTempFile()
        #expect(FileManager.default.fileExists(atPath: url.path))
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bundle = try decoder.decode(ExportBundle.self, from: data)
        #expect(bundle.events.count == 1)
    }

    @Test func backupExport_encoded_emptyProfileNil() throws {
        let data = try BackupExport(events: [], profile: nil).encoded()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bundle = try decoder.decode(ExportBundle.self, from: data)
        #expect(bundle.events.isEmpty)
        #expect(bundle.profile == nil)
    }
}
