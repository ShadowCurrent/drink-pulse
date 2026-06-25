import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct DataExportImportTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // MARK: - Export

    @Test func encode_producesValidJSON() throws {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        let data = try DataExporter().encode([event])
        #expect(!data.isEmpty)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        _ = try decoder.decode(ExportBundle.self, from: data)
    }

    @Test func encode_emptyEvents_producesValidJSON() throws {
        let data = try DataExporter().encode([])
        #expect(!data.isEmpty)
    }

    @Test func fileName_containsDate() {
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01
        let name = DataExporter().fileName(for: date)
        #expect(name.hasPrefix("drinkpulse-backup-1970-01-01"))
        #expect(name.hasSuffix(".json"))
    }

    @Test func writeTempFile_createsReadableFile() throws {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        let profile = UserProfile(bodyWeightKg: 70.0, biologicalSex: .male,
                                   guidelineChoice: .who, weeklyGoalGrams: 100.0,
                                   unitSystem: .metric, currency: "USD")
        let url = try DataExporter().writeTempFile(for: [event], profile: profile)
        #expect(FileManager.default.fileExists(atPath: url.path))
        let data = try Data(contentsOf: url)
        #expect(!data.isEmpty)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bundle = try decoder.decode(ExportBundle.self, from: data)
        #expect(bundle.version == 2)
        #expect(bundle.events.count == 1)
        #expect(bundle.profile != nil)
    }

    // MARK: - BackupExport (lazy share)

    @Test func backupExport_fileName_containsDate() {
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01
        let name = BackupExport.fileName(for: date)
        #expect(name.hasPrefix("drinkpulse-backup-1970-01-01"))
        #expect(name.hasSuffix(".json"))
    }

    @Test func backupExport_snapshotsRecordsUpFront() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        let profile = UserProfile(bodyWeightKg: 70.0, biologicalSex: .male,
                                   guidelineChoice: .who, weeklyGoalGrams: 100.0,
                                   unitSystem: .metric, currency: "USD")
        let export = BackupExport(events: [event], profile: profile)
        #expect(export.events.count == 1)
        #expect(export.profile != nil)
    }

    @Test func backupExport_encoded_producesDecodableBundle() throws {
        let event = ConsumptionEvent(volumeMl: 355, abv: 0.05, name: "Beer",
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
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
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

    @Test func encode_setsVersionTwo() throws {
        let data = try DataExporter().encode([])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bundle = try decoder.decode(ExportBundle.self, from: data)
        #expect(bundle.version == 2)
    }

    // MARK: - Round-trip (events)

    @Test func roundTrip_preservesAllFields() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let original = ConsumptionEvent(
            timestamp:  Date(timeIntervalSince1970: 1_000_000),
            volumeMl:   330,
            abv:        0.055,
            quantity:   4,
            name:       "Beer",
            category:   .beer,
            icon:       "🍺",
            customName: "Tyskie",
            notes:      "Friday night",
            price:      3.50,
            priceCurrency: "PLN"
        )
        let data = try DataExporter().encode([original])
        let result = try DataImporter().importData(data, into: context)

        #expect(result.imported == 1)
        #expect(result.skipped == 0)
        #expect(result.failed == 0)

        let fetched = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(fetched.count == 1)
        let e = try #require(fetched.first)
        #expect(abs(e.timestamp.timeIntervalSince(original.timestamp)) < 1)
        #expect(e.volumeMl == 330)
        #expect(e.quantity == 4)
        #expect(abs(e.abv - 0.055) < 0.0001)
        #expect(e.name == "Beer")
        #expect(e.category == .beer)
        #expect(e.customName == "Tyskie")
        #expect(e.notes == "Friday night")
        #expect(e.price == 3.50)
        #expect(e.priceCurrency == "PLN")
    }

    // plan-0034: per-event currency round-trips through export/import.
    @Test func roundTrip_preservesPriceCurrency() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let original = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                        category: .beer, icon: "🍺",
                                        price: 9.99, priceCurrency: "GBP")
        let data = try DataExporter().encode([original])
        _ = try DataImporter().importData(data, into: context)
        let e = try #require(try context.fetch(FetchDescriptor<ConsumptionEvent>()).first)
        #expect(e.price == 9.99)
        #expect(e.priceCurrency == "GBP")
    }

    // Backups written before plan-0034 have no priceCurrency key → decodes to nil.
    @Test func import_legacyBundleWithoutPriceCurrency_defaultsToNil() throws {
        let container = try makeContainer()
        let json = """
        {"version":2,"exportedAt":"2026-01-01T00:00:00Z","events":[
        {"timestamp":"2026-01-01T12:00:00Z","volumeMl":500,"abv":0.05,"quantity":1,
         "name":"Beer","category":"beer","icon":"🍺","price":4.20}]}
        """
        let result = try DataImporter().importData(Data(json.utf8), into: container.mainContext)
        #expect(result.imported == 1)
        let e = try #require(try container.mainContext.fetch(FetchDescriptor<ConsumptionEvent>()).first)
        #expect(e.price == 4.20)
        #expect(e.priceCurrency == nil)
    }

    // plan-0031: enteredUnit provenance round-trips through export/import.
    @Test func roundTrip_preservesEnteredUnit() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let original = ConsumptionEvent(volumeMl: 568, abv: 0.05, enteredUnit: .imperial,
                                        name: "Beer", category: .beer, icon: "🍺")
        let data = try DataExporter().encode([original])
        _ = try DataImporter().importData(data, into: context)
        let e = try #require(try context.fetch(FetchDescriptor<ConsumptionEvent>()).first)
        #expect(e.enteredUnit == .imperial)
    }

    // Backups written before plan-0031 have no enteredUnit key → decodes to nil.
    @Test func import_legacyBundleWithoutEnteredUnit_defaultsToNil() throws {
        let container = try makeContainer()
        let json = """
        {"version":2,"exportedAt":"2026-01-01T00:00:00Z","events":[
        {"timestamp":"2026-01-01T12:00:00Z","volumeMl":568,"abv":0.05,"quantity":1,
         "name":"Beer","category":"beer","icon":"🍺"}]}
        """
        let result = try DataImporter().importData(Data(json.utf8), into: container.mainContext)
        #expect(result.imported == 1)
        let e = try #require(try container.mainContext.fetch(FetchDescriptor<ConsumptionEvent>()).first)
        #expect(e.enteredUnit == nil)
    }

    // v1/v2 files predate the quantity field → it must decode to 1.
    @Test func import_legacyBundleWithoutQuantity_defaultsToOne() throws {
        let container = try makeContainer()
        let json = """
        {"version":1,"exportedAt":"2026-01-01T00:00:00Z","events":[
        {"timestamp":"2026-01-01T12:00:00Z","volumeMl":500,"abv":0.05,
         "name":"Beer","category":"beer","icon":"🍺"}]}
        """
        let result = try DataImporter().importData(Data(json.utf8), into: container.mainContext)
        #expect(result.imported == 1)
        let e = try #require(try container.mainContext.fetch(FetchDescriptor<ConsumptionEvent>()).first)
        #expect(e.quantity == 1)
    }

    @Test func roundTrip_multipleEvents() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let events: [ConsumptionEvent] = [
            ConsumptionEvent(volumeMl: 500, abv: 0.05,  name: "Beer",    category: .beer,    icon: "🍺"),
            ConsumptionEvent(volumeMl: 175, abv: 0.135, name: "Wine",    category: .wine,    icon: "🍷"),
            ConsumptionEvent(volumeMl: 40,  abv: 0.40,  name: "Spirits", category: .spirits, icon: "🥃"),
        ]
        let data = try DataExporter().encode(events)
        let result = try DataImporter().importData(data, into: context)

        #expect(result.imported == 3)
        let fetched = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(fetched.count == 3)
    }

    // MARK: - Profile round-trip

    @Test func roundTrip_profileFieldsPreserved() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let profile = UserProfile(
            bodyWeightKg: 75.5,
            biologicalSex: .female,
            guidelineChoice: .uk,
            weeklyGoalGrams: 84.0,
            unitSystem: .imperial,
            currency: "GBP",
            abvPrecisionPermille: 1,
            alcoholUnit: .standardDrinks
        )
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        let data = try DataExporter().encode([event], profile: profile)
        _ = try DataImporter().importData(data, into: context)

        let fetchedProfiles = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(fetchedProfiles.count == 1)
        let p = try #require(fetchedProfiles.first)
        #expect(p.bodyWeightKg == 75.5)
        #expect(p.biologicalSex == .female)
        #expect(p.guidelineChoice == .uk)
        #expect(p.weeklyGoalGrams == 84.0)
        #expect(p.unitSystem == .imperial)
        #expect(p.currency == "GBP")
        #expect(p.abvPrecisionPermille == 1)
        #expect(p.alcoholUnit == .standardDrinks)
    }

    @Test func import_legacyUnitsAlcoholUnit_mapsToStandardDrinks() throws {
        // plan-0029 migration: a backup written before the .units case was retired
        // must load as .standardDrinks (UK now folds into standard drinks).
        let container = try makeContainer()
        let context = container.mainContext
        let json = """
        {
          "version": 2,
          "exportedAt": "2026-01-01T00:00:00Z",
          "events": [],
          "profile": {
            "bodyWeightKg": 70,
            "biologicalSex": "male",
            "guidelineChoice": "uk",
            "weeklyGoalGrams": 100,
            "unitSystem": "metric",
            "currency": "GBP",
            "abvPrecisionPermille": 5,
            "alcoholUnit": "units"
          }
        }
        """
        _ = try DataImporter().importData(Data(json.utf8), into: context)
        let p = try #require(try context.fetch(FetchDescriptor<UserProfile>()).first)
        #expect(p.alcoholUnit == .standardDrinks)
    }

    @Test func profileUpsert_overwritesExistingProfile() throws {
        let container = try makeContainer()
        let context = container.mainContext

        // Insert existing profile with different values
        let existing = UserProfile(bodyWeightKg: 60.0, biologicalSex: .male,
                                   guidelineChoice: .who, weeklyGoalGrams: 100.0,
                                   unitSystem: .metric, currency: "USD")
        context.insert(existing)

        let importProfile = UserProfile(bodyWeightKg: 90.0, biologicalSex: .female,
                                        guidelineChoice: .de, weeklyGoalGrams: 140.0,
                                        unitSystem: .usCustomary, currency: "EUR")
        let data = try DataExporter().encode([], profile: importProfile)
        _ = try DataImporter().importData(data, into: context)

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(fetched.count == 1)  // still exactly one
        let p = try #require(fetched.first)
        #expect(p.bodyWeightKg == 90.0)
        #expect(p.biologicalSex == .female)
        #expect(p.guidelineChoice == .de)
        #expect(p.currency == "EUR")
    }

    @Test func profileUpsert_insertsWhenNoneExists() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let profile = UserProfile(bodyWeightKg: 80.0, biologicalSex: .male,
                                   guidelineChoice: .who, weeklyGoalGrams: 100.0,
                                   unitSystem: .metric, currency: "USD")
        let data = try DataExporter().encode([], profile: profile)
        _ = try DataImporter().importData(data, into: context)

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(fetched.count == 1)
    }

    // MARK: - Version handling

    @Test func import_v1Bundle_succeeds() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let json = """
        {
          "version": 1,
          "exportedAt": "2026-01-01T00:00:00Z",
          "events": [{
            "timestamp": "2026-01-01T12:00:00Z",
            "volumeMl": 500, "abv": 0.05,
            "name": "Beer", "category": "beer", "icon": "🍺"
          }]
        }
        """.data(using: .utf8)!

        let result = try DataImporter().importData(json, into: context)
        #expect(result.imported == 1)
    }

    @Test func import_unsupportedVersion_throwsError() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let json = """
        {
          "version": 999,
          "exportedAt": "2026-01-01T00:00:00Z",
          "events": []
        }
        """.data(using: .utf8)!

        #expect(throws: ImportError.self) {
            try DataImporter().importData(json, into: context)
        }
    }

    @Test func import_unsupportedVersion_errorDescriptionContainsVersion() throws {
        let error = ImportError.unsupportedVersion(42)
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("42"))
    }

    @Test func import_decodeFailure_errorDescriptionIsNonEmpty() throws {
        let underlying = NSError(domain: "test", code: 1)
        let error = ImportError.decodeFailure(underlying: underlying)
        #expect((error.errorDescription ?? "").isEmpty == false)
    }

    // MARK: - Deduplication

    @Test func import_skipsExistingDuplicates() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let ts = Date(timeIntervalSince1970: 2_000_000)
        let event = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: 0.05,
                                     name: "Beer", category: .beer, icon: "🍺")
        context.insert(event)

        let data = try DataExporter().encode([event])

        let first = try DataImporter().importData(data, into: context)
        #expect(first.skipped == 1)
        #expect(first.imported == 0)

        let fetched = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(fetched.count == 1)
    }

    @Test func importTwice_noDoubleInsert() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let events = [ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                        category: .beer, icon: "🍺")]
        let data = try DataExporter().encode(events)

        _ = try DataImporter().importData(data, into: context)
        let second = try DataImporter().importData(data, into: context)

        #expect(second.skipped == 1)
        let fetched = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(fetched.count == 1)
    }

    // MARK: - Error handling

    @Test func import_unknownCategory_countedAsFailed() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let json = """
        {
          "version": 1,
          "exportedAt": "2026-01-01T00:00:00Z",
          "events": [{
            "timestamp": "2026-01-01T12:00:00Z",
            "volumeMl": 500, "abv": 0.05,
            "name": "Mystery", "category": "INVALID_CAT", "icon": "❓"
          }]
        }
        """.data(using: .utf8)!

        let result = try DataImporter().importData(json, into: context)
        #expect(result.failed == 1)
        #expect(result.imported == 0)
        #expect(!result.errors.isEmpty)
    }

    @Test func import_malformedJSON_throwsDecodeFailure() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let badData = "not json".data(using: .utf8)!
        #expect(throws: ImportError.self) {
            try DataImporter().importData(badData, into: context)
        }
    }

    // MARK: - Content signature (stale-export regression)

    @Test func contentSignature_changesOnEventEdit() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        let sig1 = DataExporter.contentSignature(events: [event], profile: nil)
        event.notes = "updated note"
        let sig2 = DataExporter.contentSignature(events: [event], profile: nil)
        #expect(sig1 != sig2)
    }

    @Test func contentSignature_changesOnProfileEdit() {
        let profile = UserProfile(bodyWeightKg: 70.0, biologicalSex: .male,
                                   guidelineChoice: .who, weeklyGoalGrams: 100.0,
                                   unitSystem: .metric, currency: "USD")
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        let sig1 = DataExporter.contentSignature(events: [event], profile: profile)
        profile.bodyWeightKg = 85.0
        let sig2 = DataExporter.contentSignature(events: [event], profile: profile)
        #expect(sig1 != sig2)
    }

    @Test func contentSignature_stableWithSameContent() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        let sig1 = DataExporter.contentSignature(events: [event], profile: nil)
        let sig2 = DataExporter.contentSignature(events: [event], profile: nil)
        #expect(sig1 == sig2)
    }

    @Test func contentSignature_changesWhenCountChanges() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        let sig1 = DataExporter.contentSignature(events: [], profile: nil)
        let sig2 = DataExporter.contentSignature(events: [event], profile: nil)
        #expect(sig1 != sig2)
    }

    @Test func contentSignature_changesOnCustomNameEdit() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        let sig1 = DataExporter.contentSignature(events: [event], profile: nil)
        event.customName = "Hazy IPA"
        let sig2 = DataExporter.contentSignature(events: [event], profile: nil)
        #expect(sig1 != sig2)
    }

    @Test func contentSignature_changesOnCategoryEdit() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        let sig1 = DataExporter.contentSignature(events: [event], profile: nil)
        event.category = .cider
        let sig2 = DataExporter.contentSignature(events: [event], profile: nil)
        #expect(sig1 != sig2)
    }

    @Test func contentSignature_changesOnIconEdit() {
        let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, name: "Beer",
                                     category: .beer, icon: "🍺")
        let sig1 = DataExporter.contentSignature(events: [event], profile: nil)
        event.icon = "🍏"
        let sig2 = DataExporter.contentSignature(events: [event], profile: nil)
        #expect(sig1 != sig2)
    }
}
