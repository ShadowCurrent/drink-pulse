import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// Plan-0035 / Q3: the owner installs the post-change build over real device
/// data after exporting a backup, so the importer must map EVERY current JSON
/// field onto the (unchanged) schema. These tests drive the real export path
/// (`BackupExport` → `ExportBundle` JSON) into a SECOND fresh store via
/// `DataImporter` and assert every field survives.
///
/// Complements `DataImporterRoundTripTests`, which covers most fields but never
/// round-trips `UserProfile.dateOfBirth`, never asserts `ConsumptionEvent.icon`,
/// and never combines `enteredUnit` with all other event fields in one record.
@MainActor
struct ComprehensiveRoundTripTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func fullyPopulatedEventAndProfile_everyFieldRoundTrips() throws {
        let dob = Date(timeIntervalSince1970: 600_000)
        let stamp = Date(timeIntervalSince1970: 1_500_000)

        let event = ConsumptionEvent(
            timestamp: stamp, volumeMl: 568, abv: 0.052, quantity: 7,
            enteredUnit: .imperial, category: .cider,
            icon: "apple.logo", customName: "Scrumpy", notes: "Cellar door",
            price: 6.25, priceCurrency: "GBP"
        )
        let profile = UserProfile(
            bodyWeightKg: 68.5, biologicalSex: .female, dateOfBirth: dob,
            guidelineChoice: .de, weeklyGoalGrams: 96.0, unitSystem: .usCustomary,
            currency: "EUR", abvPrecisionPermille: 1, alcoholUnit: .standardDrinks
        )

        let data = try BackupExport(events: [event], profile: profile).encoded()

        let container = try makeContainer()
        let destContext = container.mainContext
        let result = try DataImporter().importData(data, into: destContext)
        #expect(result.imported == 1)
        #expect(result.failed == 0)

        let e = try #require(try destContext.fetch(FetchDescriptor<ConsumptionEvent>()).first)
        #expect(abs(e.timestamp.timeIntervalSince(stamp)) < 1)
        #expect(e.volumeMl == 568)
        #expect(abs(e.abv - 0.052) < 0.0001)
        #expect(e.quantity == 7)
        #expect(e.enteredUnit == .imperial)
        #expect(e.category == .cider)
        #expect(e.icon == "apple.logo")
        #expect(e.customName == "Scrumpy")
        #expect(e.notes == "Cellar door")
        #expect(e.price == 6.25)
        #expect(e.priceCurrency == "GBP")

        let p = try #require(try destContext.fetch(FetchDescriptor<UserProfile>()).first)
        #expect(p.bodyWeightKg == 68.5)
        #expect(p.biologicalSex == .female)
        #expect(p.dateOfBirth == dob)
        #expect(p.guidelineChoice == .de)
        #expect(p.weeklyGoalGrams == 96.0)
        #expect(p.unitSystem == .usCustomary)
        #expect(p.currency == "EUR")
        #expect(p.abvPrecisionPermille == 1)
        #expect(p.alcoholUnit == .standardDrinks)
    }

    @Test func eventWithNilOptionals_roundTripsAsNil() throws {
        let event = ConsumptionEvent(
            volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺"
        )
        let data = try BackupExport(events: [event], profile: nil).encoded()

        let container = try makeContainer()
        let destContext = container.mainContext
        _ = try DataImporter().importData(data, into: destContext)

        let e = try #require(try destContext.fetch(FetchDescriptor<ConsumptionEvent>()).first)
        #expect(e.enteredUnit == nil)
        #expect(e.customName == nil)
        #expect(e.notes == nil)
        #expect(e.price == nil)
        #expect(e.priceCurrency == nil)
    }
}
