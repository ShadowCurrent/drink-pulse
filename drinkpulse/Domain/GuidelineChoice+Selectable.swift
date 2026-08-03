import Foundation

extension GuidelineChoice {
    /// The guidelines a user can pick from, in the enum's declaration order.
    ///
    /// `.custom` is excluded deliberately: it is a *derived* state the app assigns
    /// when a user overrides thresholds themselves, never a value offered in a list
    /// of guidelines to choose between.
    ///
    /// This is the single source of the pickable list for **both** the Settings
    /// guideline picker and the onboarding guideline step. Hard-coding a parallel
    /// list anywhere else reintroduces finding A1-2 — the two screens silently
    /// diverging the day a seventh guideline is added.
    ///
    /// Stored, not computed, on purpose: a computed property filtered in a view's
    /// `body` allocates a fresh array on every body pass. This is built once, at
    /// first access.
    static let selectable: [GuidelineChoice] = GuidelineChoice.allCases.filter { $0 != .custom }
}
