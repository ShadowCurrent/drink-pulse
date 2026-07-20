import Foundation

/// Direction of a week-over-week change, independent of whether an exact
/// percentage is meaningful (see `WeeklySummaryContent.directionOnly`).
nonisolated enum SignDirection: Equatable, Sendable {
    case up
    case down
    case same
}

/// The classified content of a weekly-summary notification. Pure data —
/// no formatting, no localization. The consumer (Service/UI layer) maps
/// each case to its localized copy.
nonisolated enum WeeklySummaryContent: Equatable, Sendable {
    /// No prior week of data exists at all (first-ever week, ENGG-06).
    /// The notification must not be sent.
    case skip
    /// Prior week had zero grams, but real prior-week data exists
    /// (ENGG-05) — an exact percentage would be meaningless/undefined,
    /// so only the direction is reported.
    case directionOnly(SignDirection)
    /// A real week-over-week percentage change (ENGG-04). `fraction` is
    /// the raw `(current - prior) / prior` ratio, not yet rounded or
    /// converted to a whole percent.
    case percentage(fraction: Double, direction: SignDirection)
}

/// Pure, Sendable week-over-week content classifier for the weekly-summary
/// notification (ENGG-03/04/05/06). No SwiftUI, SwiftData, or
/// UserNotifications dependency — takes plain grams and returns a plain
/// enum so it is trivially unit-testable and reusable from the Service
/// layer (plan 01-02).
nonisolated enum WeeklySummaryCalculator {
    /// Classifies the week-over-week change given the current and prior
    /// week's total pure-alcohol grams.
    ///
    /// - Parameters:
    ///   - currentWeekGrams: Total pure-alcohol grams logged in the current period's
    ///     window (which may still be in progress — the production caller,
    ///     `WeeklySummaryService.scheduleIfEnabled`, passes the in-progress calendar
    ///     week, mirroring `InsightsViewModel.trendFraction`'s live "This Week"
    ///     semantics; see the inline comment below).
    ///   - priorWeekGrams: Total pure-alcohol grams logged in the period before that.
    ///   - hasAnyPriorWeekData: Whether any `ConsumptionEvent` exists before the
    ///     current week's start at all — distinct from `priorWeekGrams == 0`,
    ///     which can mean "a real sober week" (ENGG-05) rather than "no history
    ///     yet" (ENGG-06).
    static func content(
        currentWeekGrams: Double,
        priorWeekGrams: Double,
        hasAnyPriorWeekData: Bool
    ) -> WeeklySummaryContent {
        guard hasAnyPriorWeekData else { return .skip }

        // Strict, no epsilon — mirrors InsightsViewModel.trendFraction's guard
        // exactly. A logged 0.0%-ABV event does not make priorWeekGrams non-zero.
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
