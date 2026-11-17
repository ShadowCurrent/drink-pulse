import XCTest

/// App content occluded by the system tab bar during an accessibility audit (owner decision D11-29).
///
/// D11-29 amends D11-25: an audit evaluates the launch viewport, except app content while it sits
/// under the system tab bar. The tab bar is Liquid Glass chrome drawn over the scrolling content,
/// so the pixel-based checks measure that content through the glass, not against its own card.
///
/// The rule is decided at audit time from the real tab bar element, never from a list of names:
/// - only `contrast` and `textClipped` issues can be ignored (the two checks that read rendered
///   pixels); every other audit type always fails;
/// - the issue must carry an element whose frame intersects the tab bar frame;
/// - an element of the tab bar itself (system chrome) is never ignored, so a chrome finding still
///   fails (plan 11-17 stop rule);
/// - an issue without an element is never ignored, because it cannot be located.
///
/// When a match is unsure (a name or frame shared with the tab bar), the issue is treated as chrome
/// and fails; a doubtful case is never ignored.
@MainActor
struct AuditTabBarOcclusion {

    /// The audit types that read rendered pixels and so are distorted by the glass tab bar.
    static let occlusionSensitiveTypes: XCUIAccessibilityAuditType = [.contrast, .textClipped]

    let tabBarFrame: CGRect
    private let chromeNames: Set<String>
    private let chromeFrames: [CGRect]

    /// Reads the tab bar shown now, or nil when the screen shows none (then nothing is ignored).
    static func current(in app: XCUIApplication) throws -> AuditTabBarOcclusion? {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else { return nil }
        let snapshot = try tabBar.snapshot()
        guard !snapshot.frame.isEmpty else { return nil }
        var names: Set<String> = []
        var frames: [CGRect] = []
        collect(snapshot, names: &names, frames: &frames)
        return AuditTabBarOcclusion(tabBarFrame: snapshot.frame, chromeNames: names, chromeFrames: frames)
    }

    private static func collect(
        _ snapshot: any XCUIElementSnapshot,
        names: inout Set<String>,
        frames: inout [CGRect]
    ) {
        for name in [snapshot.identifier, snapshot.label] where !name.isEmpty {
            names.insert(name)
        }
        frames.append(snapshot.frame)
        for child in snapshot.children {
            collect(child, names: &names, frames: &frames)
        }
    }

    /// The element frame when the issue is ignored under D11-29, else nil (the issue fails).
    func occludedFrame(for issue: XCUIAccessibilityAuditIssue) -> CGRect? {
        guard Self.occlusionSensitiveTypes.contains(issue.auditType),
              let element = issue.element
        else { return nil }
        let frame = element.frame
        let overlap = frame.intersection(tabBarFrame)
        guard !overlap.isNull, overlap.width > 0, overlap.height > 0 else { return nil }
        guard !isChrome(element, frame: frame) else { return nil }
        return frame
    }

    private func isChrome(_ element: XCUIElement, frame: CGRect) -> Bool {
        let named = [element.identifier, element.label].contains { !$0.isEmpty && chromeNames.contains($0) }
        return named || chromeFrames.contains { Self.sameFrame($0, frame) }
    }

    private static func sameFrame(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.minX - rhs.minX) < 1 && abs(lhs.minY - rhs.minY) < 1
            && abs(lhs.width - rhs.width) < 1 && abs(lhs.height - rhs.height) < 1
    }

    /// `x,y,w,h` rounded to integers, the same form as the unlabeled element key.
    static func text(for frame: CGRect) -> String {
        [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height]
            .map { String(Int($0.rounded())) }
            .joined(separator: ",")
    }
}
