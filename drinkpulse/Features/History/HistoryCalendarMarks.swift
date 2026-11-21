import Foundation

/// Risk level per calendar day for the History calendar decorations (plan 0045, D0045-8).
enum HistoryCalendarMarks {

    /// Keys are start-of-day dates. Days with no alcohol are absent, and a non-positive
    /// limit yields no marks. Mass uses `density` (display unit) against physical-gram
    /// limits, the documented convention (AGENTS.md "Calculations").
    static func levels(
        events: [ConsumptionEvent],
        dailyLimitGrams: Double,
        density: Double,
        calendar: Calendar
    ) -> [Date: RiskLevel] {
        guard dailyLimitGrams > 0 else { return [:] }
        let grams = events.reduce(into: [Date: Double]()) { acc, event in
            acc[calendar.startOfDay(for: event.consumptionDate), default: 0] +=
                event.alcoholGrams(density: density)
        }
        return grams.reduce(into: [Date: RiskLevel]()) { acc, entry in
            guard entry.value > 0 else { return }
            acc[entry.key] = RiskLevel.from(pct: entry.value / dailyLimitGrams)
        }
    }
}
