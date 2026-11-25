import XCTest

/// Owner decision D0048-18 (2026-11-25, plan 0048): the onboarding primary button keeps the
/// `.glassProminent` style for a uniform iOS 27 look. On the simulator the audit then reports one
/// `contrast` issue that carries no element (with `.borderedProminent` the same audit passes).
/// Only that exact shape is exempted, on onboarding screens only, and each one is recorded as a
/// warning by `assertNoAuditIssues(exemptSystemControl:)`. A `contrast` issue with an element, and
/// every other element-less type, still fails. To be checked with Accessibility Inspector on a
/// device (plan 0048 "Device check").
enum OnboardingAuditExemptions {
    @MainActor
    static func glassPrimaryButton(_ issue: XCUIAccessibilityAuditIssue) -> String? {
        guard issue.auditType == .contrast, issue.element == nil else { return nil }
        return "D0048-18 element-less contrast, onboarding glassProminent primary button"
    }
}
