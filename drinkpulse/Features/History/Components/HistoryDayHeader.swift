import SwiftUI

/// Section header of one History day: title leading, "N drinks · total" trailing; stacks when
/// the line no longer fits (large Dynamic Type) via `ViewThatFits` (plan 0045, D0045-2).
struct HistoryDayHeader: View {
    let title: String
    let total: HistoryDayTotal
    let unitContext: RowUnitContext

    private var totalText: Text {
        let amount = unitContext.alcoholUnit.formattedValue(total.massGrams, guideline: unitContext.guideline)
        let unit = unitContext.alcoholUnit.unitLabel(for: unitContext.guideline)
        // Automatic grammar agreement: "1 drink", "2 drinks".
        return Text("history.dayHeader.total \(total.drinkCount) \(amount) \(unit)")
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                Spacer(minLength: 8)
                totalText.monospacedDigit()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                totalText.monospacedDigit()
            }
        }
        // The system grey fails contrast on the Frost tint (open question "Contrast-safe
        // secondary ink").
        .foregroundStyle(Color.dpSecondaryText)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("history.dayHeader")
    }
}

private let previewTotal = HistoryDayTotal(drinkCount: 3, massGrams: 42)
private let previewUnits = RowUnitContext(alcoholUnit: .standardDrinks, guideline: .who, unitSystem: .metric)

#Preview("Header") {
    List {
        Section {
            Text(verbatim: "Row")
        } header: {
            HistoryDayHeader(title: "Today", total: previewTotal, unitContext: previewUnits)
        }
        Section {
            Text(verbatim: "Row")
        } header: {
            HistoryDayHeader(title: "Saturday 14 Nov", total: HistoryDayTotal(drinkCount: 1, massGrams: 14),
                             unitContext: previewUnits)
        }
    }
    .listStyle(.insetGrouped)
}

#Preview("Header · AX5") {
    List {
        Section {
            Text(verbatim: "Row")
        } header: {
            HistoryDayHeader(title: "Wednesday 18 Nov", total: previewTotal, unitContext: previewUnits)
        }
    }
    .listStyle(.insetGrouped)
    .dynamicTypeSize(.accessibility5)
}
