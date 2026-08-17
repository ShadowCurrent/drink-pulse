import SwiftUI

struct EventRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .title2) private var iconWidth: Double = 36

    let event: ConsumptionEvent
    let unitContext: RowUnitContext

    private let strings: EventRowStrings

    init(event: ConsumptionEvent, unitContext: RowUnitContext) {
        self.event = event
        self.unitContext = unitContext
        self.strings = EventRowStrings(event: event, unitContext: unitContext)
    }

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
        EventRow(event: .previewSpirits, unitContext: RowUnitContext(nil))
    }
}
