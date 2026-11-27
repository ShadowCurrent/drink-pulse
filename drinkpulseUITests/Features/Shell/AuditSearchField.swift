import XCTest

/// The native search field's placeholder reports `textClipped` (element-less, described as a
/// `UISearchBarTextField`) although the app does not size or style it. Owner decision for the
/// History search field (2026-11-21, plan 0045 Task 6), applied to Add Drink's search field
/// (plan 0047 Task 6). Only this one audit type on this one system control; recorded as a warning.
enum AuditSearchField {
    static func exemption(_ issue: XCUIAccessibilityAuditIssue) -> String? {
        guard issue.auditType == .textClipped,
              issue.detailedDescription.contains("UISearchBarTextField")
        else { return nil }
        return "native search field placeholder"
    }
}
