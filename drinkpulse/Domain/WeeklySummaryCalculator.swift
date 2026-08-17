import Foundation

nonisolated enum SignDirection: Equatable, Sendable {
    case up
    case down
    case same
}

nonisolated enum WeeklySummaryContent: Equatable, Sendable {
    case skip
    case directionOnly(SignDirection)
    case percentage(fraction: Double, direction: SignDirection)
}

nonisolated enum WeeklySummaryCalculator {
    static func content(
        currentWeekGrams: Double,
        priorWeekGrams: Double,
        hasAnyPriorWeekData: Bool
    ) -> WeeklySummaryContent {
        guard hasAnyPriorWeekData else { return .skip }

        guard priorWeekGrams > 0 else {
            return currentWeekGrams > 0 ? .directionOnly(.up) : .directionOnly(.same)
        }

        let fraction = (currentWeekGrams - priorWeekGrams) / priorWeekGrams
        if abs(fraction) <= 0.05 {
            return .percentage(fraction: fraction, direction: .same)
        }
        return .percentage(fraction: fraction, direction: fraction < 0 ? .down : .up)
    }
}
