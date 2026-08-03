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

    /// A note is announced to VoiceOver — and only when there actually is one.
    /// `nil` and `""` must both read as "no note": an event whose note was cleared
    /// in the Edit sheet stores an empty string, not `nil`, so treating the two
    /// differently would announce a note that is not there. Finding C14-5.
    @Test func accessibilityLabel_announcesANote_onlyWhenOneIsPresent() throws {
        let c = try makeContainer()
        let notePhrase = String(localized: "history.row.hasNote")

        let noted = beer(in: c.mainContext)
        noted.notes = "Shared at dinner"
        let unnoted = beer(in: c.mainContext)          // notes stays nil
        let emptyNoted = beer(in: c.mainContext)
        emptyNoted.notes = ""

        let withNote = EventRowStrings(event: noted, unitContext: metricWho)
        let withoutNote = EventRowStrings(event: unnoted, unitContext: metricWho)
        let withEmptyNote = EventRowStrings(event: emptyNoted, unitContext: metricWho)

        #expect(withNote.accessibilityLabel.hasSuffix(", \(notePhrase)"))
        #expect(withNote.accessibilityLabel.hasPrefix(withoutNote.accessibilityLabel))
        #expect(!withoutNote.accessibilityLabel.contains(notePhrase))
        #expect(withEmptyNote.accessibilityLabel == withoutNote.accessibilityLabel)
    }

    /// The note affects the spoken label ONLY. Every visible field stays
    /// byte-identical, so the glyph in the row — not the text — is what changes.
    @Test func visibleFields_areUnchangedByANote() throws {
        let c = try makeContainer()

        let noted = beer(in: c.mainContext)
        noted.notes = "Shared at dinner"
        let unnoted = beer(in: c.mainContext)

        let withNote = EventRowStrings(event: noted, unitContext: metricWho)
        let withoutNote = EventRowStrings(event: unnoted, unitContext: metricWho)

        #expect(withNote.name == withoutNote.name)
        #expect(withNote.subtitle == withoutNote.subtitle)
        #expect(withNote.amount == withoutNote.amount)
        #expect(withNote.unitLabel == withoutNote.unitLabel)
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
