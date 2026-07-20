import Foundation

/// Stable `@AppStorage` keys shared across the app. Centralised so a typo in
/// one call site can't silently desync a binding from its writer.
nonisolated enum AppStorageKeys {
    static let onboardingDone = "dp_onboarding_done"
    static let colorScheme = "dp_color_scheme"

    // Log-reminder local notification (plan-0016).
    static let reminderEnabled = "dp_reminder_enabled"
    static let reminderHour = "dp_reminder_hour"
    static let reminderMinute = "dp_reminder_minute"
    /// Set when the user taps the reminder; read & cleared by the shell on
    /// appear so the "open Add Drink" action survives a cold launch.
    static let pendingAddDrink = "dp_pending_add_drink"

    /// Opt-in Apple Health write-back (plan-0036). Off by default; shared by the
    /// Settings toggle (W4) and the onboarding opt-in (W8) so the two stay in
    /// sync. The Add/Edit/Delete write hooks (W5) read it to decide whether to
    /// mirror a change into Health.
    static let healthWriteEnabled = "dp_health_write_enabled"

    // Weekly-summary local notification (phase-01, v1.1). Off by default;
    // shared by the Settings toggle and the onboarding opt-in so the two
    // stay in sync. Fixed 9am schedule — no hour/minute picker keys.
    static let weeklySummaryEnabled = "dp_weekly_summary_enabled"
    /// Set when the user taps the weekly-summary notification; read & cleared
    /// by the shell on appear so the "open Insights" action survives a cold launch.
    static let pendingOpenInsights = "dp_pending_open_insights"
}
