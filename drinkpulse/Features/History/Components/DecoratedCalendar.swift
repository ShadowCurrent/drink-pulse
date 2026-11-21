import SwiftUI
import UIKit

/// System calendar (`UICalendarView`) wrapped for SwiftUI, because the graphical `DatePicker`
/// cannot mark dates (plan 0045, D0045-8; prototype round 7). This is the History screen's one
/// allowed UIKit wrapper.
///
/// Marks use the app's `RiskLevel` with shape + size + colour, so colour is never the only cue
/// (HIG Inclusive color): small dot = safe, medium dot = caution, exclamation symbol = exceeded.
/// Decoration views cannot be interactive (UIKit docs), so selection stays the system's.
struct DecoratedCalendar: UIViewRepresentable {
    @Binding var selection: Date
    /// Any date in the month the calendar shows; two-way, so "Today" can page back.
    @Binding var visibleMonth: Date
    /// Start of day → risk level; days without alcohol are absent.
    let marks: [Date: RiskLevel]
    /// Earliest event's month … now; `setVisibleDateComponents` must stay inside it.
    let availableRange: DateInterval

    private static var calendar: Calendar { .current }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = Self.calendar
        view.availableDateRange = availableRange
        view.delegate = context.coordinator
        let single = UICalendarSelectionSingleDate(delegate: context.coordinator)
        single.selectedDate = Self.components(selection)
        view.selectionBehavior = single
        view.tintColor = UIColor(Brand.accent)
        view.visibleDateComponents = Self.components(clamped(visibleMonth))
        view.accessibilityIdentifier = "history.calendar"
        return view
    }

    func updateUIView(_ view: UICalendarView, context: Context) {
        let oldMarks = context.coordinator.parent.marks
        context.coordinator.parent = self
        if view.availableDateRange != availableRange {
            view.availableDateRange = availableRange
        }

        let changed = Set(oldMarks.keys).union(marks.keys).filter { oldMarks[$0] != marks[$0] }
        if !changed.isEmpty {
            view.reloadDecorations(forDateComponents: changed.map(Self.components), animated: true)
        }

        let animated = DPMotion.animation(.default, reduceMotion: context.environment.accessibilityReduceMotion) != nil
        let target = clamped(visibleMonth)
        if let shown = Self.calendar.date(from: view.visibleDateComponents),
           !Self.calendar.isDate(shown, equalTo: target, toGranularity: .month) {
            view.setVisibleDateComponents(Self.components(target), animated: animated)
        }
        if let single = view.selectionBehavior as? UICalendarSelectionSingleDate,
           single.selectedDate.flatMap(Self.calendar.date(from:)) != Self.calendar.startOfDay(for: selection) {
            single.setSelected(Self.components(selection), animated: animated)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UICalendarView, context: Context) -> CGSize? {
        let width = proposal.width ?? 360
        let fitted = uiView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: width, height: fitted.height)
    }

    private func clamped(_ date: Date) -> Date {
        min(max(date, availableRange.start), availableRange.end)
    }

    static func components(_ date: Date) -> DateComponents {
        calendar.dateComponents([.calendar, .year, .month, .day], from: date)
    }

    static func decoration(for level: RiskLevel) -> UICalendarView.Decoration {
        let color = UIColor(level.tone)
        switch level {
        case .safe:
            return .default(color: color, size: .small)
        case .caution:
            return .default(color: color, size: .medium)
        case .exceeded:
            return .image(UIImage(systemName: "exclamationmark.circle.fill"), color: color, size: .large)
        }
    }

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: DecoratedCalendar

        init(parent: DecoratedCalendar) { self.parent = parent }

        func calendarView(_ calendarView: UICalendarView,
                          decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = DecoratedCalendar.calendar.date(from: dateComponents),
                  let level = parent.marks[DecoratedCalendar.calendar.startOfDay(for: date)] else { return nil }
            return DecoratedCalendar.decoration(for: level)
        }

        func calendarView(_ calendarView: UICalendarView,
                          didChangeVisibleDateComponentsFrom previousDateComponents: DateComponents) {
            guard let shown = DecoratedCalendar.calendar.date(from: calendarView.visibleDateComponents),
                  !DecoratedCalendar.calendar.isDate(shown, equalTo: parent.visibleMonth, toGranularity: .month)
            else { return }
            parent.visibleMonth = shown
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate,
                           didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents, let date = DecoratedCalendar.calendar.date(from: dateComponents) else { return }
            parent.selection = DecoratedCalendar.calendar.startOfDay(for: date)
        }

        /// Future days are not selectable; nil (deselect) is refused so a day stays selected.
        func dateSelection(_ selection: UICalendarSelectionSingleDate,
                           canSelectDate dateComponents: DateComponents?) -> Bool {
            guard let dateComponents, let date = DecoratedCalendar.calendar.date(from: dateComponents) else { return false }
            return date <= .now
        }
    }
}
