import SwiftUI

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
