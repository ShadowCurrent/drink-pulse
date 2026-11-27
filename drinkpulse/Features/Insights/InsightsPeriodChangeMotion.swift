import SwiftUI

/// Decides how an Insights period navigation animates (prev / next / Today). A Week / Month / …
/// switch is never animated (see `InsightsView.periodBinding`).
///
/// A spaced-out change gets the full page animation, including the Swift Charts curve morph
/// (D0046-9). A change that follows the previous one within `rapidInterval` is applied without
/// animation: Swift Charts' per-frame mark interpolation piled up on rapid taps and hung the main
/// thread (Time Profiler on device, 2026-11-26), while un-animated swaps stayed smooth. No tap is
/// dropped or delayed. Reduce Motion: never animated.

nonisolated enum InsightsPeriodChangeMotion {
    /// Changes closer together than this are treated as rapid navigation.
    static let rapidInterval: TimeInterval = 0.2

    /// The period-change animation: `.snappy`, shortened so a single step settles quickly.
    static let animation: Animation = .snappy(duration: 0.2)

    /// `true` when a change at `now` follows the previous one (`last`) within `rapidInterval`.
    static func isRapid(now: Date, last: Date?) -> Bool {
        guard let last else { return false }
        let elapsed = now.timeIntervalSince(last)
        return elapsed >= 0 && elapsed < rapidInterval
    }

    /// The animation to use for a change at `now`, or `nil` to apply it instantly.
    static func animation(now: Date, last: Date?, reduceMotion: Bool) -> Animation? {
        guard !isRapid(now: now, last: last) else { return nil }
        return DPMotion.animation(animation, reduceMotion: reduceMotion)
    }
}
