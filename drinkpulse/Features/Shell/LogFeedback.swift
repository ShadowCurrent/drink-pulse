import Foundation
import SwiftUI

/// Chooses the haptic for one logged drink: `.warning` when that drink takes today over the
/// daily limit, `.success` otherwise (plan 0044 D0044-3).
///
/// "Over the limit" is `DashboardViewModel.todayPct > 1`, the same value the Today hero shows,
/// so no limit formula is duplicated here.
@MainActor
enum LogFeedback {

    /// - Parameter todayEvents: today's events, including `logged` when it is dated today.
    static func feedback(
        todayEvents: [ConsumptionEvent],
        logged: ConsumptionEvent,
        profile: UserProfile?,
        now: Date,
        calendar: Calendar
    ) -> SensoryFeedback {
        let after = todayPct(todayEvents, profile: profile, now: now, calendar: calendar)
        let before = todayPct(
            todayEvents.filter { $0 !== logged }, profile: profile, now: now, calendar: calendar
        )
        return before <= 1 && after > 1 ? .warning : .success
    }

    private static func todayPct(
        _ events: [ConsumptionEvent], profile: UserProfile?, now: Date, calendar: Calendar
    ) -> Double {
        let model = DashboardViewModel()
        model.events = events
        model.profile = profile
        model.now = now
        model.calendar = calendar
        return model.todayPct
    }
}
