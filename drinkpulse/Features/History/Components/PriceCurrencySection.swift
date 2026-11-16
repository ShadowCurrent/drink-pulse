import SwiftUI

struct PriceCurrencySection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var priceText: String
    @Binding var currencyCode: String

    private var selected: CurrencyOption { CurrencyCatalog.option(for: currencyCode) }

    var body: some View {
        Section(String(localized: "addDrink.price")) {
            DPAdaptiveStack(spacing: 12) {
                priceField
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !dynamicTypeSize.isAccessibilitySize {
                    Divider()
                        .frame(height: 24)
                }

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

    /// A vertical-axis field wraps its placeholder at accessibility sizes; regular sizes keep
    /// the single-line field.
    @ViewBuilder
    private var priceField: some View {
        if dynamicTypeSize.isAccessibilitySize {
            TextField(String(localized: "addDrink.pricePlaceholder"), text: $priceText, axis: .vertical)
        } else {
            TextField(String(localized: "addDrink.pricePlaceholder"), text: $priceText)
        }
    }
}

#Preview("Accessibility 5") {
    @Previewable @State var price = ""
    @Previewable @State var code = "EUR"
    return Form {
        PriceCurrencySection(priceText: $price, currencyCode: $code)
    }
    .dynamicTypeSize(.accessibility5)
}

#Preview {
    @Previewable @State var price = "12.50"
    @Previewable @State var code = "EUR"
    return Form {
        PriceCurrencySection(priceText: $price, currencyCode: $code)
    }
}
