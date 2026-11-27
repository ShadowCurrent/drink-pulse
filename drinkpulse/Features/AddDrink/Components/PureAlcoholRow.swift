import SwiftUI

/// The live result of the serving wheels in the user's display unit, e.g. "1.4 std" (D0047-7).
/// The figure rolls when it changes; under Reduce Motion it changes without animation. Display
/// only: the mass comes from the caller and is not recomputed here.
struct PureAlcoholRow: View {
    let grams: Double
    let alcoholUnit: AlcoholUnit
    let guideline: GuidelineChoice

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var valueText: String {
        "\(alcoholUnit.formattedValue(grams, guideline: guideline)) \(alcoholUnit.unitLabel(for: guideline))"
    }

    var body: some View {
        LabeledContent(String(localized: "addDrink.pureAlcohol")) {
            Text(valueText)
                .fontDesign(.rounded)
                .monospacedDigit()
                .contentTransition(.numericText(value: grams))
        }
        .animation(reduceMotion ? nil : .snappy, value: grams)
        .brandRowBackground()
    }
}

#Preview("Standard drinks") {
    Form {
        Section { PureAlcoholRow(grams: 20, alcoholUnit: .standardDrinks, guideline: .who) }
    }
    .brandListBackground()
}

#Preview("Grams · Dark") {
    Form {
        Section { PureAlcoholRow(grams: 19.725, alcoholUnit: .grams, guideline: .who) }
    }
    .brandListBackground()
    .preferredColorScheme(.dark)
}

#Preview("AX5") {
    Form {
        Section { PureAlcoholRow(grams: 20, alcoholUnit: .standardDrinks, guideline: .uk) }
    }
    .brandListBackground()
    .dynamicTypeSize(.accessibility5)
}
