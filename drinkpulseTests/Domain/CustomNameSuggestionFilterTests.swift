import Testing
import Foundation
@testable import drinkpulse

struct CustomNameSuggestionFilterTests {

    // MARK: - Empty query

    @Test func suggestions_returnsEmpty_whenQueryIsEmpty() {
        let result = CustomNameSuggestionFilter.suggestions(for: "", in: ["Craft IPA", "Barolo Riserva"])
        #expect(result.isEmpty)
    }

    // MARK: - Case-insensitive substring match, alphabetical order

    @Test func suggestions_matchesCaseInsensitively_sortedAlphabetically() {
        let names = ["barolo riserva", "Zinfandel", "Craft IPA"]
        let result = CustomNameSuggestionFilter.suggestions(for: "a", in: names)
        #expect(result == ["barolo riserva", "Craft IPA", "Zinfandel"])
    }

    @Test func suggestions_excludesNonMatchingCandidates() {
        let names = ["Craft IPA", "Barolo Riserva"]
        let result = CustomNameSuggestionFilter.suggestions(for: "zzz", in: names)
        #expect(result.isEmpty)
    }

    // MARK: - Case-insensitive duplicate collapse

    @Test func suggestions_collapsesCaseInsensitiveDuplicates() {
        let names = ["Craft IPA", "craft ipa", "CRAFT IPA"]
        let result = CustomNameSuggestionFilter.suggestions(for: "craft", in: names)
        #expect(result.count == 1)
        #expect(result == ["CRAFT IPA"])
    }

    // MARK: - Blank / whitespace-only candidates ignored

    @Test func suggestions_ignoresBlankAndWhitespaceOnlyCandidates() {
        let names = ["Craft IPA", "   ", ""]
        let result = CustomNameSuggestionFilter.suggestions(for: "craft", in: names)
        #expect(result == ["Craft IPA"])
    }

    // MARK: - Exact match exclusion

    @Test func suggestions_excludesCandidateThatExactlyMatchesQuery_caseInsensitive() {
        let names = ["Craft IPA", "Craft IPA Session"]
        let result = CustomNameSuggestionFilter.suggestions(for: "craft ipa", in: names)
        #expect(result == ["Craft IPA Session"])
    }

    @Test func suggestions_excludesExactMatch_leavingLongerSharedPrefixMatch() {
        let names = ["Barolo", "Barolo Riserva"]
        let result = CustomNameSuggestionFilter.suggestions(for: "Barolo", in: names)
        #expect(result == ["Barolo Riserva"])
    }

    // MARK: - Limit cap

    @Test func suggestions_capsResultsAtLimit() {
        let names = ["Ale 1", "Ale 2", "Ale 3", "Ale 4", "Ale 5"]
        let result = CustomNameSuggestionFilter.suggestions(for: "Ale", in: names, limit: 3)
        #expect(result.count == 3)
        #expect(result == ["Ale 1", "Ale 2", "Ale 3"])
    }

    @Test func suggestions_defaultLimitIsEight() {
        let names = (1...10).map { "Ale \($0)" }
        let result = CustomNameSuggestionFilter.suggestions(for: "Ale", in: names)
        #expect(result.count == 8)
    }
}
