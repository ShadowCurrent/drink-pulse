import Foundation

extension Calendar {
    /// Every start-of-day `Date` from the range's lower to upper bound,
    /// inclusive. Stepping is via Calendar arithmetic, so callers that hit this
    /// repeatedly (e.g. per-metric reduces) should cache the result — see
    /// `InsightsViewModel.activeDays`.
    func days(in range: ClosedRange<Date>) -> [Date] {
        var result: [Date] = []
        var current = startOfDay(for: range.lowerBound)
        let end = startOfDay(for: range.upperBound)
        while current <= end {
            result.append(current)
            guard let next = date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return result
    }
}
