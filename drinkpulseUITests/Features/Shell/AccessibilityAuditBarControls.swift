import Foundation

/// Element keys of system bar controls whose AX5 `dynamicType` / `textClipped` findings are
/// exempt (plan 0040 audit policy, prototype round 21, owner accepted 2026-11-20).
///
/// Navigation-bar and tab-bar items keep a fixed size at accessibility text sizes and offer the
/// Large Content Viewer instead (UIKit `UILargeContentViewerInteraction`: "for cases when
/// supporting the largest dynamic type sizes isn't appropriate"). The exemption is passed per
/// call through `exemptElementKeys`, AX5 variants only; `isExempt` limits it to `dynamicType`
/// and `textClipped`, so every other finding on these controls still fails.
///
/// Add a tab-bar key only when an audit run reports one (plan 0044 Task 4: none reported).
enum AuditBarControls {
    /// The `+` primary action on Today, Insights and History (`AddDrinkToolbarItem`).
    static let addDrink = "addDrink.button"

    static let keys: Set<String> = [addDrink]
}
