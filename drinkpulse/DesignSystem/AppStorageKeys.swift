import Foundation

/// Stable `@AppStorage` keys shared across the app. Centralised so a typo in
/// one call site can't silently desync a binding from its writer.
enum AppStorageKeys {
    static let onboardingDone = "dp_onboarding_done"
    static let colorScheme = "dp_color_scheme"

    // Log-reminder local notification (plan-0016).
    static let reminderEnabled = "dp_reminder_enabled"
    static let reminderHour = "dp_reminder_hour"
    static let reminderMinute = "dp_reminder_minute"
    /// Set when the user taps the reminder; read & cleared by the shell on
    /// appear so the "open Add Drink" action survives a cold launch.
    static let pendingAddDrink = "dp_pending_add_drink"
}
