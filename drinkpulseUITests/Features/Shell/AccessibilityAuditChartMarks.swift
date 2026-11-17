import XCTest

/// The labelled day-mark elements of a chart whose `hitRegion` findings are not evaluated (owner
/// decision D11-30).
///
/// Swift Charts gives each mark element a few points of width and has no API to enlarge a mark's
/// hit region, so a chart with one accessibility element per day cannot meet the 44 pt hit-region
/// check. D11-30 keeps those elements (VoiceOver still moves day by day) and exempts only their
/// `hitRegion` findings. The rule is decided at audit time from the real chart element, never from a
/// list of names:
/// - only `hitRegion` issues can be exempted; every other audit type always fails;
/// - the issue must carry an element whose label and frame equal those of a direct, labelled child
///   of the chart element (a day mark);
/// - an issue without an element, or on any other element, always fails.
@MainActor
final class AuditChartDayMarks {

    private struct Mark {
        let label: String
        let frame: CGRect
    }

    private let chart: XCUIElement
    /// Read on the first `hitRegion` issue, after the audit has run, so chart marks that were still
    /// animating in when the audit started are compared at their settled frames.
    private var marks: [Mark]?

    private init(chart: XCUIElement) {
        self.chart = chart
    }

    /// The chart with the given accessibility label, or nil when it is not shown (then nothing is
    /// exempted).
    static func current(chartLabel: String, in app: XCUIApplication) -> AuditChartDayMarks? {
        let chart = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", chartLabel)).firstMatch
        return chart.exists ? AuditChartDayMarks(chart: chart) : nil
    }

    /// The element frame when the issue is exempted under D11-30, else nil (the issue fails).
    func exemptFrame(for issue: XCUIAccessibilityAuditIssue) -> CGRect? {
        guard issue.auditType == .hitRegion, let element = issue.element else { return nil }
        let label = element.label
        let frame = element.frame
        let isDayMark = dayMarks().contains { $0.label == label && Self.sameFrame($0.frame, frame) }
        return isDayMark ? frame : nil
    }

    /// Direct, labelled children of the chart element: the day marks.
    private func dayMarks() -> [Mark] {
        if let marks { return marks }
        // A failed snapshot leaves no marks, so nothing is exempted and every issue fails: safe.
        let read = ((try? chart.snapshot().children) ?? [])
            .filter { !$0.label.isEmpty }
            .map { Mark(label: $0.label, frame: $0.frame) }
        marks = read
        return read
    }

    private static func sameFrame(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.minX - rhs.minX) < 1 && abs(lhs.minY - rhs.minY) < 1
            && abs(lhs.width - rhs.width) < 1 && abs(lhs.height - rhs.height) < 1
    }
}

extension XCTestCase {

    /// Records one issue exempted under D11-30 as a warning with its type, label and frame.
    @MainActor
    func recordExemptedDayMarkIssue(
        _ issue: XCUIAccessibilityAuditIssue,
        frame: CGRect,
        screen: String,
        variant: String,
        file: StaticString,
        line: UInt
    ) {
        let typeName = AccessibilityAuditKey.typeName(for: issue.auditType)
        let elementKey = AccessibilityAuditKey.elementKey(for: issue.element)
        recordAuditWarning("Accessibility audit issue ignored (D11-30, chart day mark): "
                           + "screen=\(screen) variant=\(variant) type=\(typeName) element=\(elementKey) "
                           + "frame=\(AuditTabBarOcclusion.text(for: frame))",
                           file: file, line: line)
    }

    /// Records the per-variant count of issues exempted under D11-30, also when it is zero.
    @MainActor
    func recordExemptedDayMarkCount(
        _ count: Int,
        chartFound: Bool,
        screen: String,
        variant: String,
        file: StaticString,
        line: UInt
    ) {
        recordAuditWarning("Accessibility audit ignored count (D11-30): screen=\(screen) "
                           + "variant=\(variant) ignored=\(count) chartFound=\(chartFound)",
                           file: file, line: line)
    }
}
