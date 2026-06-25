import SwiftUI

/// Price entry plus a per-event currency override (plan-0034). The currency is
/// seeded from the profile currency by the host view and persisted *with* the
/// price, so a stored amount is never reinterpreted when the profile currency
/// later changes. Shared by the Add (`DrinkDetailInputView`) and Edit
/// (`EditEventView`) forms.
///
/// Single-line row: the price field flexes to fill, a hairline `|` separates it
/// from a `.menu` currency picker whose label shows the full "<code> · <symbol>"
/// (sized to content so the selection is never truncated).
struct PriceCurrencySection: View {
    @Binding var priceText: String
    @Binding var currencyCode: String

    private var selected: CurrencyOption { CurrencyCatalog.option(for: currencyCode) }

    var body: some View {
        Section(String(localized: "addDrink.price")) {
            HStack(spacing: 12) {
                TextField(String(localized: "addDrink.pricePlaceholder"), text: $priceText)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 24)

                // Whole label (value + chevron) opens the Menu. `.tint(.primary)`
                // keeps the selected value in the normal font color (a Menu would
                // otherwise tint its label with the accent); the chevron then
                // re-takes the accent via an explicit `.foregroundStyle`.
                Menu {
                    Picker(String(localized: "addDrink.currency"), selection: $currencyCode) {
                        ForEach(CurrencyCatalog.common) { option in
                            Text("\(option.code) · \(option.symbol)").tag(option.code)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("\(selected.code) · \(selected.symbol)")
                            .font(.body)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(Color.accentColor)
                    }
                    .fixedSize()
                }
                .tint(.primary)
                .accessibilityLabel(String(localized: "addDrink.currency"))
                .accessibilityValue(selected.code)
            }
        }
    }
}

#Preview {
    @Previewable @State var price = "12.50"
    @Previewable @State var code = "EUR"
    return Form {
        PriceCurrencySection(priceText: $price, currencyCode: $code)
    }
}
