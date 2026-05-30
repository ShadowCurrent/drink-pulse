import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct DrinkControlImporterTests {

    private static let header = "AccountedForDate;RegisteredDate;Name;Serving;DrinkSizeInMl;AlcoholVolumePercentage;NumberOfDrinks;PriceForSingleDrink;TotalPrice;TotalAlcoholInGrams;TotalUnits(Germany);TotalAlcoholCalories;TotalCalories"

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func csv(_ dataLines: String...) -> String {
        ([Self.header] + dataLines).joined(separator: "\n")
    }

    // MARK: - previewCount

    @Test func previewCount_excludesHeader() {
        let input = csv(
            "2026-01-02 12:00:00;2026-01-02 18:00:00;\"beer\";\"Bottle\";500;0.050;1;0.00;0.00;19.73;1.97;138;138",
            "2026-01-03 12:00:00;2026-01-03 20:00:00;\"beer\";\"Bottle\";500;0.050;1;0.00;0.00;19.73;1.97;138;138"
        )
        #expect(DrinkControlImporter().previewCount(input) == 2)
    }

    @Test func previewCount_emptyCSV_returnsZero() {
        #expect(DrinkControlImporter().previewCount("") == 0)
    }

    @Test func previewCount_headerOnly_returnsZero() {
        #expect(DrinkControlImporter().previewCount(Self.header) == 0)
    }

    // MARK: - Field mapping

    @Test func validBeerRow_mapsCorrectFields() throws {
        let container = try makeContainer()
        let input = csv("2026-01-02 12:00:00;2026-01-02 18:30:45;\"beer\";\"Bottle\";500;0.050;1;0.00;0.00;19.73;1.97;138;138")

        let result = DrinkControlImporter().importCSV(input, into: container.mainContext)

        #expect(result.imported == 1)
        #expect(result.failed  == 0)

        let events = try container.mainContext.fetch(FetchDescriptor<ConsumptionEvent>())
        let e = try #require(events.first)
        #expect(e.volumeMl == 500)
        #expect(abs(e.abv - 0.05) < 0.0001)
        #expect(e.category == .beer)
        #expect(e.icon == "🍺")
        #expect(e.customName == "Bottle")
    }

    @Test func timestamp_usesRegisteredDate() throws {
        let container = try makeContainer()
        // AccountedForDate = noon, RegisteredDate = actual time
        let input = csv("2026-01-10 12:00:00;2026-01-10 20:42:48;\"beer\";\"Bottle\";500;0.050;1;0.00;0.00;19.73;1.97;138;138")
        _ = DrinkControlImporter().importCSV(input, into: container.mainContext)

        let events = try container.mainContext.fetch(FetchDescriptor<ConsumptionEvent>())
        let e = try #require(events.first)
        let cal = Calendar.current
        #expect(cal.component(.hour,   from: e.timestamp) == 20)
        #expect(cal.component(.minute, from: e.timestamp) == 42)
    }

    // MARK: - NumberOfDrinks > 1

    @Test func multipleCount_combinedVolumeAsSingleEvent() throws {
        let container = try makeContainer()
        let input = csv("2026-01-17 12:00:00;2026-01-17 21:14:26;\"beer\";\"Med bottle\";330;0.050;3;0.00;0.00;39.07;3.91;273;273")

        let result = DrinkControlImporter().importCSV(input, into: container.mainContext)
        #expect(result.imported == 1)

        let events = try container.mainContext.fetch(FetchDescriptor<ConsumptionEvent>())
        let e = try #require(events.first)
        #expect(e.volumeMl == 330 * 3)
    }

    @Test func multipleCount_customNameHasCountPrefix() throws {
        let container = try makeContainer()
        let input = csv("2026-01-17 12:00:00;2026-01-17 21:14:26;\"beer\";\"Med bottle\";330;0.050;3;0.00;0.00;39.07;3.91;273;273")
        _ = DrinkControlImporter().importCSV(input, into: container.mainContext)

        let events = try container.mainContext.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(events.first?.customName == "3× Med bottle")
    }

    @Test func singleCount_customNameIsServingOnly() throws {
        let container = try makeContainer()
        let input = csv("2026-01-02 12:00:00;2026-01-02 18:00:00;\"beer\";\"Bottle\";500;0.050;1;0.00;0.00;19.73;1.97;138;138")
        _ = DrinkControlImporter().importCSV(input, into: container.mainContext)

        let events = try container.mainContext.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(events.first?.customName == "Bottle")
    }

    // MARK: - Category mapping

    @Test func vodkaCategory_mapsToSpirits() throws {
        let container = try makeContainer()
        let input = csv("2026-05-17 12:00:00;2026-05-17 17:51:08;\"vodka\";\"Sml double\";40;0.380;1;0.00;0.00;12.00;1.20;84;84")
        _ = DrinkControlImporter().importCSV(input, into: container.mainContext)

        let events = try container.mainContext.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(events.first?.category == .spirits)
        #expect(events.first?.icon == "🥃")
    }

    @Test func otherCategory_mapsToCustom() throws {
        let container = try makeContainer()
        let input = csv("2026-01-10 12:00:00;2026-01-10 20:42:48;\"other\";\"Sml shot\";20;0.380;1;0.00;0.00;6.00;0.60;42;42")
        _ = DrinkControlImporter().importCSV(input, into: container.mainContext)

        let events = try container.mainContext.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(events.first?.category == .custom)
        #expect(events.first?.icon == "🥤")
    }

    @Test func unknownCategory_mapsToCustom() throws {
        let container = try makeContainer()
        let input = csv("2026-01-01 12:00:00;2026-01-01 12:00:00;\"absinthe\";\"Shot\";30;0.700;1;0.00;0.00;16.80;1.68;118;118")
        _ = DrinkControlImporter().importCSV(input, into: container.mainContext)

        let events = try container.mainContext.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(events.first?.category == .custom)
    }

    // MARK: - Error handling

    @Test func malformedRow_countedAsFailed_restImported() throws {
        let container = try makeContainer()
        let input = csv(
            "BAD ROW",
            "2026-01-02 12:00:00;2026-01-02 18:00:00;\"beer\";\"Bottle\";500;0.050;1;0.00;0.00;19.73;1.97;138;138"
        )
        let result = DrinkControlImporter().importCSV(input, into: container.mainContext)

        #expect(result.failed  == 1)
        #expect(result.imported == 1)
        #expect(!result.errors.isEmpty)
    }

    // MARK: - Deduplication

    @Test func deduplication_skipsExistingEntry() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let ts = Date(timeIntervalSince1970: 1_735_900_800)  // deterministic

        let existing = ConsumptionEvent(timestamp: ts, volumeMl: 500, abv: 0.05,
                                         name: "Beer", category: .beer, icon: "🍺")
        ctx.insert(existing)

        let input = csv("2026-01-02 12:00:00;2026-01-02 18:00:00;\"beer\";\"Bottle\";500;0.050;1;0.00;0.00;19.73;1.97;138;138")
        // Use a fresh container (this entry won't exist yet)
        let freshContainer = try makeContainer()
        _ = DrinkControlImporter().importCSV(input, into: freshContainer.mainContext)
        let imported = try freshContainer.mainContext.fetch(FetchDescriptor<ConsumptionEvent>())
        #expect(imported.count == 1)

        // Re-import the same CSV → should be skipped
        let result = DrinkControlImporter().importCSV(input, into: freshContainer.mainContext)
        #expect(result.skipped == 1)
        #expect(result.imported == 0)
    }
}
