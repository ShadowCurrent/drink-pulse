import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// Regression for quick 261127-l7y: date of birth left the profile, but version-2 backups
/// written before that still carry the key. They must import cleanly, and a fresh export
/// must not bring the key back. Every value is synthetic.
@MainActor
struct LegacyDateOfBirthImportTests {

    private static let legacyKey = "dateOfBirth"

    private static let legacyBundle = """
    {
      "version": 2,
      "exportedAt": "2026-01-15T12:00:00Z",
      "events": [
        {
          "uuid": "00000000-0000-4000-8000-0000000000a1",
          "timestamp": "2026-01-05T09:00:00Z",
          "volumeMl": 500,
          "abv": 0.05,
          "category": "beer",
          "icon": "🍺"
        }
      ],
      "templates": [],
      "profile": {
        "bodyWeightKg": 81.5,
        "biologicalSex": "female",
        "dateOfBirth": "1990-01-01T00:00:00Z",
        "guidelineChoice": "uk",
        "weeklyGoalGrams": 112.0,
        "unitSystem": "imperial",
        "currency": "GBP",
        "abvPrecisionPermille": 1,
        "alcoholUnit": "grams",
        "modifiedDate": "2026-01-10T00:00:00Z"
      }
    }
    """

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func legacyBackupWithDateOfBirth_importsWithoutFailures_andIsNotReExported() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let data = try #require(Self.legacyBundle.data(using: .utf8))

        let result = try DataImporter().importData(data, into: context)
        #expect(result.failed == 0)
        #expect(result.imported == 1)

        let profile = try #require(try context.fetch(FetchDescriptor<UserProfile>()).first)
        #expect(profile.bodyWeightKg == 81.5)
        #expect(profile.biologicalSex == .female)
        #expect(profile.guidelineChoice == .uk)
        #expect(profile.weeklyGoalGrams == 112.0)
        #expect(profile.unitSystem == .imperial)
        #expect(profile.currency == "GBP")
        #expect(profile.abvPrecisionPermille == 1)
        #expect(profile.alcoholUnit == .grams)

        let events = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        let exported = try BackupExport(events: events, profile: profile).encoded()
        let json = try #require(String(data: exported, encoding: .utf8))
        #expect(!json.contains(Self.legacyKey))

        let object = try #require(try JSONSerialization.jsonObject(with: exported) as? [String: Any])
        #expect(object["version"] as? Int == 2)
    }
}
