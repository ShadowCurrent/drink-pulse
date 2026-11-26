import Foundation

/// The single rule behind every alcohol-free and heavy-day number (Insights and Today).
///
/// - Counting starts on the calendar day of the first logged event of any kind (0 % ABV
///   included). Days before it, and every day when there are no events, are not counted.
/// - Finished days (before today) count: alcohol-free at 0 g, otherwise drinking.
/// - Today counts only once it has alcohol; future days never count.
/// - A heavy day is one with at least 60 g (WHO heavy episodic drinking).
///
/// Grams are supplied by the caller in display-unit grams, keyed by start of day, so the
/// density convention stays with the caller. See `docs/domain.md`.
nonisolated struct AlcoholFreeDayRule: Sendable {
    static let heavyDayThresholdGrams: Double = 60

    private let calendar: Calendar
    private let startDay: Date?
    private let today: Date

    init(firstEventDate: Date?, now: Date, calendar: Calendar) {
        self.calendar = calendar
        self.startDay = firstEventDate.map { calendar.startOfDay(for: $0) }
        self.today = calendar.startOfDay(for: now)
    }

    static func isHeavy(grams: Double) -> Bool {
        grams >= heavyDayThresholdGrams
    }

    static func heavyDayCount(in days: [Date], grams: (Date) -> Double) -> Int {
        days.count { isHeavy(grams: grams($0)) }
    }

    func status(of day: Date, grams: Double) -> AlcoholFreeDayStatus {
        let day = calendar.startOfDay(for: day)
        guard let startDay, day >= startDay, day <= today else { return .notCounted }
        if grams > 0 { return .drinking }
        return day == today ? .notCounted : .alcoholFree
    }

    func alcoholFreeDays(in days: [Date], grams: (Date) -> Double) -> (count: Int, total: Int) {
        let statuses = statuses(of: days, grams: grams)
        return (statuses.count { $0 == .alcoholFree }, statuses.count { $0 != .notCounted })
    }

    func longestAlcoholFreeStreak(in days: [Date], grams: (Date) -> Double) -> Int {
        var longest = 0
        var current = 0
        for status in statuses(of: days, grams: grams) {
            current = status == .alcoholFree ? current + 1 : 0
            longest = max(longest, current)
        }
        return longest
    }

    func alcoholFreeDates(in days: [Date], grams: (Date) -> Double) -> [Date] {
        days.map { calendar.startOfDay(for: $0) }
            .filter { status(of: $0, grams: grams($0)) == .alcoholFree }
    }

    /// Alcohol-free days in a row ending yesterday; 0 when today already has alcohol.
    /// Bounded by the start day, so it never runs past the first log.
    func currentAlcoholFreeStreak(grams: (Date) -> Double) -> Int {
        guard status(of: today, grams: grams(today)) != .drinking else { return 0 }
        var streak = 0
        var day = calendar.date(byAdding: .day, value: -1, to: today)
        // Normalise each step: where DST skips midnight, the day before can land on 01:00.
        while let raw = day {
            let current = calendar.startOfDay(for: raw)
            guard status(of: current, grams: grams(current)) == .alcoholFree else { break }
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: current)
        }
        return streak
    }

    private func statuses(of days: [Date], grams: (Date) -> Double) -> [AlcoholFreeDayStatus] {
        days.map { day in
            let start = calendar.startOfDay(for: day)
            return status(of: start, grams: grams(start))
        }
    }
}
