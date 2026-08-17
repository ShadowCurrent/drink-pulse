import Foundation

nonisolated enum CustomNameSuggestionFilter {
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
