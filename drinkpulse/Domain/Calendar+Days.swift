import Foundation

extension Calendar {
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
