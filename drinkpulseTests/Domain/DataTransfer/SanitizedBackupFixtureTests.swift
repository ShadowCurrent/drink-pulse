import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct SanitizedBackupFixtureTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private struct Counts: Equatable {
        let events: Int
        let templates: Int
        let profiles: Int
    }

    private func counts(in context: ModelContext) throws -> Counts {
        Counts(
            events: try context.fetch(FetchDescriptor<ConsumptionEvent>()).count,
            templates: try context.fetch(FetchDescriptor<DrinkTemplate>()).count,
            profiles: try context.fetch(FetchDescriptor<UserProfile>()).count
        )
    }

    private func exportedJSON(from context: ModelContext) throws -> String {
        let events = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        let templates = try context.fetch(FetchDescriptor<DrinkTemplate>())
        let profile = try context.fetch(FetchDescriptor<UserProfile>()).first
        let data = try BackupExport(events: events, templates: templates, profile: profile).encoded()
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - Probe (synthetic export proves loading and the importer path)

    @Test func probe_loaderReturnsNonEmptyData() throws {
        let data = try BackupFixtureLoader.data(named: "probe-export-v2")
        #expect(!data.isEmpty)
    }

    @Test func probe_importsWithoutFailures_andReimportIsNoOp() throws {
        let data = try BackupFixtureLoader.data(named: "probe-export-v2")
        let context = try makeContainer().mainContext

        let first = try DataImporter().importData(data, into: context)
        try context.save()
        let afterFirst = try counts(in: context)
        let second = try DataImporter().importData(data, into: context)
        try context.save()

        #expect(first.failed == 0)
        #expect(first.imported == 3)
        #expect(second.imported == 0)
        #expect(second.failed == 0)
        #expect(afterFirst == Counts(events: 3, templates: 1, profiles: 1))
        #expect(try counts(in: context) == afterFirst)
    }

    @Test func probe_exportOfImportedStoreHasNoHealthKitUUID() throws {
        let data = try BackupFixtureLoader.data(named: "probe-export-v2")
        let context = try makeContainer().mainContext
        _ = try DataImporter().importData(data, into: context)
        try context.save()

        #expect(!(try exportedJSON(from: context)).contains("healthKitUUID"))
    }
}
