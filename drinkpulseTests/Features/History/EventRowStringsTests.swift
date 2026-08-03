import Testing
import Foundation
import SwiftData
@testable import drinkpulse

/// Pins that a History row's visible strings and its accessibility label come from
/// one computation and cannot drift apart. Expected values are built by calling the
/// same domain APIs rather than hard-coding formatted literals — the simulator's
/// system locale is not English, so hard-coded numbers would be locale-fragile.
/// Finding A4-1.
@MainActor
struct EventRowStringsTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func beer(abv: Double = 0.05, in context: ModelContext) -> ConsumptionEvent {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let e = ConsumptionEvent(consumptionDate: date, volumeMl: 500, abv: abv,
                                 category: .beer, icon: "🍺")
        context.insert(e)
        return e
    }

    private let metricWho = RowUnitContext(alcoholUnit: .standardDrinks,
                                           guideline: .who,
                                           unitSystem: .metric)

    @Test func subtitleAndAmount_matchTheDomainFormatters() throws {
        let c = try makeContainer()
        let event = beer(in: c.mainContext)
        let strings = EventRowStrings(event: event, unitContext: metricWho)

        let expectedVolume = UnitSystem.metric.formatVolume(500)
        let expectedAbv = String(format: "%.1f%%", 5.0)
        let expectedTime = event.consumptionDate.formatted(.dateTime.hour().minute())
        let expectedMass = event.alcoholGrams(density: metricWho.density)
        let expectedAmount = AlcoholUnit.standardDrinks.formattedValue(expectedMass, guideline: .who)

        #expect(strings.subtitle == "\(expectedVolume) · \(expectedAbv) · \(expectedTime)")
        #expect(strings.amount == expectedAmount)
        #expect(strings.name == event.displayName(in: .metric))
        #expect(strings.unitLabel == AlcoholUnit.standardDrinks.unitLabel(for: .who))
    }

    @Test func accessibilityLabel_reusesTheVisibleValues() throws {
        let c = try makeContainer()
        let event = beer(in: c.mainContext)
        let strings = EventRowStrings(event: event, unitContext: metricWho)

        let volume = UnitSystem.metric.formatVolume(500)
        #expect(strings.accessibilityLabel.contains(strings.name))
        #expect(strings.accessibilityLabel.contains(volume))
        #expect(strings.accessibilityLabel.contains(strings.amount))
        #expect(strings.accessibilityLabel.contains(strings.unitLabel))
    }

    /// Changing only the unit context changes every unit-dependent string.
    /// (`.grams` stands in for the plan's `.units`, retired in plan-0029.)
    @Test func changingOnlyTheUnitContext_changesEveryUnitDependentString() throws {
        let c = try makeContainer()
        let event = beer(in: c.mainContext)

        let imperialGrams = RowUnitContext(alcoholUnit: .grams,
                                           guideline: .uk,
                                           unitSystem: .imperial)
        let a = EventRowStrings(event: event, unitContext: metricWho)
        let b = EventRowStrings(event: event, unitContext: imperialGrams)

        #expect(a.subtitle != b.subtitle)
        #expect(a.amount != b.amount)
        #expect(a.unitLabel != b.unitLabel)
        #expect(a != b)
    }

    @Test func zeroAbvEvent_stillYieldsWellFormedStrings() throws {
        let c = try makeContainer()
        let event = beer(abv: 0.0, in: c.mainContext)
        let strings = EventRowStrings(event: event, unitContext: metricWho)

        #expect(!strings.amount.isEmpty)
        #expect(!strings.subtitle.isEmpty)
        #expect(strings.amount == AlcoholUnit.standardDrinks.formattedValue(0, guideline: .who))
        #expect(strings.subtitle.contains(String(format: "%.1f%%", 0.0)))
    }
}
