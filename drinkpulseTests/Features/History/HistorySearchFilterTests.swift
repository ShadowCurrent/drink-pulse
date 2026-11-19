import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct HistorySearchFilterTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// Seeds "Tyskie" (200 days ago, outside the 90-day list window),
    /// "Żywiec", "Guinness", a nil name and an empty-string name (as an
    /// import can produce), then fetches with the filter's predicate.
    private func fetchNames(text: String, scope: HistorySearchScope) throws -> [String?] {
        let container = try makeContainer()
        let context = container.mainContext
        let now = Date.now
        let old = Calendar.current.date(byAdding: .day, value: -200, to: now) ?? now
        let seeds: [(String?, Date)] = [
            ("Tyskie", old), ("Żywiec", now), ("Guinness", now), (nil, now), ("", now)
        ]
        for (name, date) in seeds {
            context.insert(ConsumptionEvent(
                consumptionDate: date, volumeMl: 500, abv: 0.05,
                category: .beer, icon: "🍺", customName: name
            ))
        }
        try context.save()
        let filter = HistorySearchFilter(text: text, scope: scope)
        return try context.fetch(FetchDescriptor(predicate: filter.predicate)).map(\.customName)
    }

    private func sortedNames(_ names: [String?]) -> [String] {
        names.compactMap { $0 }.sorted()
    }

    @Test func test_isActive_false_forBlankTextAndAllScope() {
        #expect(HistorySearchFilter(text: "   ", scope: .all).isActive == false)
    }

    @Test func test_isActive_true_forScopeOnly() {
        #expect(HistorySearchFilter(text: "", scope: .named).isActive == true)
    }

    @Test func test_query_isTrimmed() {
        #expect(HistorySearchFilter(text: "  tysk \n", scope: .all).query == "tysk")
    }

    @Test func test_predicate_all_matchesSubstringCaseInsensitive() throws {
        // Tyskie is 200 days old: a match also proves no 90-day window applies.
        #expect(sortedNames(try fetchNames(text: "tysk", scope: .all)) == ["Tyskie"])
    }

    @Test func test_predicate_all_noText_matchesEverything() throws {
        #expect(try fetchNames(text: "  ", scope: .all).count == 5)
    }

    @Test func test_predicate_all_ignoresDiacritics() throws {
        #expect(sortedNames(try fetchNames(text: "zyw", scope: .all)) == ["Żywiec"])
    }

    @Test func test_predicate_named_noText_excludesNilAndEmpty() throws {
        let names = try fetchNames(text: "", scope: .named)
        #expect(names.count == 3)
        #expect(sortedNames(names) == ["Guinness", "Tyskie", "Żywiec"])
    }

    @Test func test_predicate_named_withText_filtersNamed() throws {
        #expect(sortedNames(try fetchNames(text: "guin", scope: .named)) == ["Guinness"])
    }

    @Test func test_predicate_unnamed_noText_returnsNilAndEmpty() throws {
        let names = try fetchNames(text: "", scope: .unnamed)
        #expect(names.count == 2)
        #expect(names.allSatisfy { $0 == nil || $0 == "" })
    }

    @Test func test_predicate_unnamed_withText_returnsNothing() throws {
        #expect(try fetchNames(text: "a", scope: .unnamed).isEmpty)
    }

    @Test func test_emptyState_unnamedWithText_isUnnamedHasNoName() {
        #expect(HistorySearchFilter(text: "a", scope: .unnamed).emptyState == .unnamedHasNoName)
    }

    @Test func test_emptyState_otherwise_isNoMatches() {
        #expect(HistorySearchFilter(text: "x", scope: .all).emptyState == .noMatches)
    }
}
