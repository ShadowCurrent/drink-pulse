import Foundation

/// Pure filtering logic for the Custom Name tap-to-autocomplete suggestion list
/// (Add/Edit drink screens). Sourced from the user's own prior
/// `ConsumptionEvent.customName` values — never a hardcoded list, never synced.
/// No SwiftUI/SwiftData dependency: the host component (`CustomNameSuggestionSection`)
/// owns the `@Query` and passes plain `[String]` candidates in.
nonisolated enum CustomNameSuggestionFilter {
    /// Suggestions for `query` drawn from `names`.
    ///
    /// - Parameters:
    ///   - query: The text currently typed into the Custom Name field.
    ///   - names: Candidate prior `customName` values (may contain duplicates,
    ///     mixed case, and blank/whitespace-only entries).
    ///   - limit: Maximum number of suggestions to return (default 8).
    /// - Returns: Distinct candidates that case-insensitively contain `query`,
    ///   excluding any candidate that case-insensitively equals `query` exactly
    ///   (the value the user already fully typed), sorted alphabetically
    ///   case-insensitively, capped at `limit`. Empty when `query` is empty.
    static func suggestions(for query: String, in names: [String], limit: Int = 8) -> [String] {
        guard !query.isEmpty else { return [] }

        var seen = Set<String>()
        var result: [String] = []

        let sortedCandidates = names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        for rawName in sortedCandidates {
            guard result.count < limit else { break }

            let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let dedupKey = trimmed.lowercased()
            guard !seen.contains(dedupKey) else { continue }

            guard trimmed.localizedCaseInsensitiveContains(query) else { continue }
            guard trimmed.caseInsensitiveCompare(query) != .orderedSame else { continue }

            seen.insert(dedupKey)
            result.append(trimmed)
        }

        return result
    }
}
