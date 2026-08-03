import SwiftUI

/// A single History row's visible content — a plain-data view.
///
/// It stores no observable object and does no formatting: every string comes
/// from `EventRowStrings`, built once in `init` rather than re-derived on each
/// body pass (finding A4-1), and the display units arrive as a `RowUnitContext`
/// value rather than as the observable profile model the row used to read
/// (finding A6-1). The row is content only — the tap target, context menu and
/// separator live in `EventRowButton`, which is the single definition of the
/// row hierarchy for both the History list and the calendar day detail.
struct EventRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The icon column tracks `.title2` — the icon's own text style — so it stays
    /// proportional to the glyph instead of clipping it at accessibility sizes.
    @ScaledMetric(relativeTo: .title2) private var iconWidth: Double = 36

    let event: ConsumptionEvent
    let unitContext: RowUnitContext

    private let strings: EventRowStrings

    init(event: ConsumptionEvent, unitContext: RowUnitContext) {
        self.event = event
        self.unitContext = unitContext
        self.strings = EventRowStrings(event: event, unitContext: unitContext)
    }

    /// Three columns competing for one line cannot survive AX sizes: the name and
    /// the amount each need most of the width. At accessibility sizes the row
    /// stacks instead. `AnyLayout` erases a *layout*, not a view, so the subviews
    /// keep their identity across the swap — unlike branching on two whole
    /// hierarchies, which would rebuild them. Finding C14-3.
    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    var body: some View {
        layout {
            Text(event.icon)
                .font(.title2)
                .frame(width: iconWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(strings.name)
                        .font(.body)
                    if event.notes?.isEmpty == false {
                        // Announced through the row's accessibility label instead
                        // (EventRowStrings, C14-5); a bare glyph reads as noise.
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                Text(strings.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // No Spacer in the stacked branch: it would push the amount column to
            // the bottom of an expanded row instead of letting leading alignment hold.
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }

            VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing,
                   spacing: 2) {
                Text(strings.amount)
                    .monospacedDigit()
                    .font(.body.weight(.medium))
                Text(strings.unitLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(strings.accessibilityLabel)
    }
}

#Preview {
    List {
        EventRow(event: .previewBeer,
                 unitContext: RowUnitContext(alcoholUnit: .standardDrinks,
                                             guideline: .who,
                                             unitSystem: .metric))
        EventRow(event: .previewWine,
                 unitContext: RowUnitContext(alcoholUnit: .grams,
                                             guideline: .uk,
                                             unitSystem: .imperial))
        // Fallback path: no stored profile at all.
        EventRow(event: .previewSpirits, unitContext: RowUnitContext(nil))
    }
}
