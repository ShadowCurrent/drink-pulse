import XCTest

/// Owner decision D0048-18 (2026-11-25, plan 0048; widened the same day): on onboarding screens,
/// a `contrast` issue that carries no element is recorded as a warning instead of failing. Known
/// sources, localized by swapping one control at a time:
/// - the `.glassProminent` primary button (Welcome standard: 1; with `.borderedProminent` it is
///   gone). The owner keeps the glass button for a uniform iOS 27 look;
/// - the disabled Continue on About You before a sex is chosen (standard 1, AX5 3). WCAG 1.4.3
///   exempts inactive controls, and Continue must stay disabled (D0048-4);
/// - one more on About You standard that stays with a non-glass primary, an enabled Continue, a
///   non-glass Back and a borderless "Add Date of Birth": most likely the system segmented control
///   with no selection. (The "Add Date of Birth" button no longer exists since 2026-11-27, quick
///   261127-l7y.)
/// A `contrast` issue with an element, and every other element-less type, still fails. To be
/// checked with Accessibility Inspector on a device (plan 0048 "Device check").
enum OnboardingAuditExemptions {
    @MainActor
    static func glassPrimaryButton(_ issue: XCUIAccessibilityAuditIssue) -> String? {
        guard issue.auditType == .contrast, issue.element == nil else { return nil }
        return "D0048-18 element-less contrast on onboarding (glass primary, disabled Continue, segmented control)"
    }
}
