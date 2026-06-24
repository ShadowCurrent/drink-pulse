import Foundation

/// Stable `@AppStorage` keys shared across the app. Centralised so a typo in
/// one call site can't silently desync a binding from its writer.
enum AppStorageKeys {
    static let onboardingDone = "dp_onboarding_done"
    static let colorScheme = "dp_color_scheme"
}
