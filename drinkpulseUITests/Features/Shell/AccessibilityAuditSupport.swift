import XCTest

/// Builds the stable, language-independent key an audit issue is recorded under.
///
/// The simulator system language may be Polish, so keys never use the localized issue
/// description. They hold the audit type name and an element key only.
@MainActor
enum AccessibilityAuditKey {

    /// Lower-camel name of an audit type; any other type maps to `raw` plus the raw value.
    /// `action` and `parentChild` exist only on macOS (XCUIAccessibilityAuditTypes.h), so on iOS
    /// they fall through to the raw form.
    static func typeName(for type: XCUIAccessibilityAuditType) -> String {
        switch type {
        case .contrast: "contrast"
        case .elementDetection: "elementDetection"
        case .hitRegion: "hitRegion"
        case .sufficientElementDescription: "sufficientElementDescription"
        case .dynamicType: "dynamicType"
        case .textClipped: "textClipped"
        case .trait: "trait"
        default: "raw\(type.rawValue)"
        }
    }

    /// Identifier, else label. An element with neither (or no element) gets a locatable key:
    /// `none#type=<elementType rawValue>@x,y,w,h` with the frame rounded to integers.
    static func elementKey(for element: XCUIElement?) -> String {
        guard let element else { return "none#type=nil" }
        let named = [element.identifier, element.label].first { !$0.isEmpty }
        let raw = named ?? unlabeledKey(for: element)
        return raw
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: " ")
    }

    private static func unlabeledKey(for element: XCUIElement) -> String {
        let frame = element.frame
        let rect = [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height]
            .map { String(Int($0.rounded())) }
            .joined(separator: ",")
        return "none#type=\(element.elementType.rawValue)@\(rect)"
    }
}

/// Launch arguments shared by every audit variant.
enum AuditLaunch {

    static let ax5Category = "UICTContentSizeCategoryAccessibilityXXXL"

    /// Seeded multi-day arguments, or the onboarding arguments, plus an optional content size.
    static func arguments(onboarding: Bool, contentSizeCategory: String?) -> [String] {
        var arguments: [String]
        if onboarding {
            arguments = [
                "-dp_uitest", "YES",
                "-dp_force_onboarding", "YES",
            ]
        } else {
            arguments = [
                "-dp_onboarding_done", "YES",
                "-dp_uitest", "YES",
                "-dp_uitest_dataset", "multiday",
                "-dp_uitest_unit", "metric",
            ]
        }
        if let contentSizeCategory {
            arguments += ["-UIPreferredContentSizeCategoryName", contentSizeCategory]
        }
        return arguments
    }
}
