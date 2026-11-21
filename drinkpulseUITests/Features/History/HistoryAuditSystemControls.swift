import XCTest

/// System-owned History controls whose audit findings the app cannot fix (owner decision,
/// 2026-11-21, plan 0045 Task 6). Each rule is narrow: one audit type on one system control,
/// located by key or by frame, and every exempted finding is recorded as a warning.
///
/// - The native search field's placeholder ("Search by name") reports `textClipped` at every size.
/// - The keyboard's empty QuickType suggestion slots report `sufficientElementDescription` while
///   search is focused (unlabelled buttons in the band just above the keyboard).
/// - `UICalendarView` does not scale its day numbers, so the calendar reports `dynamicType` for
///   day cells (located inside the `history.calendar` frame) and for element-less calendar parts.
///   Only the calendar variants pass `calendar: true`.
@MainActor
enum HistoryAuditSystemControls {

    static let searchPlaceholderKey = "Search by name"

    static func exemption(in app: XCUIApplication, calendar: Bool = false) -> (XCUIAccessibilityAuditIssue) -> String? {
        let keyboard = app.keyboards.firstMatch
        let keyboardFrame = keyboard.exists ? keyboard.frame : nil
        let calendarElement = app.descendants(matching: .any)["history.calendar"]
        let calendarFrame = calendar && calendarElement.exists ? calendarElement.frame : nil

        return { issue in
            let key = AccessibilityAuditKey.elementKey(for: issue.element)
            switch issue.auditType {
            case .textClipped where key == searchPlaceholderKey:
                return "native search field placeholder"
            case .sufficientElementDescription:
                guard let keyboardFrame, let element = issue.element, element.label.isEmpty else { return nil }
                // QuickType bar: directly above (or inside) the keyboard.
                let band = keyboardFrame.insetBy(dx: 0, dy: -60)
                return band.contains(element.frame) ? "keyboard suggestion slot" : nil
            case .dynamicType:
                guard let calendarFrame else { return nil }
                guard let element = issue.element else { return "UICalendarView (element-less)" }
                return calendarFrame.contains(element.frame) ? "UICalendarView day cell" : nil
            default:
                return nil
            }
        }
    }
}
