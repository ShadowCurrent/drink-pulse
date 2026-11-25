import SwiftUI

/// Volume, strength and count, shared by Add Drink step 2 and Edit Drink (plan 0047).
///
/// Three `.wheel` pickers side by side (SwiftUI has no multi-component picker). At
/// accessibility sizes the wheels cannot show their values, so the same pickers become
/// `.navigationLink` rows with visible labels.
struct DrinkServingSection: View {
    @Binding var volumeMl: Double
    @Binding var abv: Double
    @Binding var count: Int
    let volumeOptions: [DrinkTypePreset.VolumeOption]
    let abvValues: [Double]
    let unitSystem: UnitSystem

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .callout) private var wheelHeight: Double = 160
    @ScaledMetric(relativeTo: .callout) private var strengthWidth: Double = 88
    @ScaledMetric(relativeTo: .callout) private var countWidth: Double = 60

    var body: some View {
        Section {
            if dynamicTypeSize.isAccessibilitySize {
                Group {
                    volumePicker
                    strengthPicker
                    countPicker
                }
                .pickerStyle(.navigationLink)
            } else {
                HStack(spacing: 0) {
                    volumePicker.frame(maxWidth: .infinity)
                    strengthPicker.frame(width: strengthWidth)
                    countPicker.frame(width: countWidth)
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(height: wheelHeight)
            }
        } header: {
            if dynamicTypeSize.isAccessibilitySize {
                Text(String(localized: "addDrink.serving")).foregroundStyle(Color.dpSecondaryText)
            } else {
                // Column titles for the wheels, which hide their own labels. A title keeps one
                // line and may overhang its narrow column ("Amount" over the 60 pt count wheel).
                HStack(spacing: 0) {
                    Text(String(localized: "addDrink.volume")).frame(maxWidth: .infinity)
                    Text(String(localized: "addDrink.strength")).fixedSize()
                        .frame(width: strengthWidth)
                    Text(String(localized: "addDrink.amount")).fixedSize()
                        .frame(width: countWidth)
                }
                // Contrast-safe ink on the Frost tint (plan 0043: system grey is 3.2:1).
                .foregroundStyle(Color.dpSecondaryText)
            }
        }
        .brandRowBackground()
    }

    // Wheel rows do not inherit the container font, so each row sets `.callout`.
    private var volumePicker: some View {
        Picker(String(localized: "addDrink.volume"), selection: $volumeMl) {
            ForEach(volumeOptions, id: \.volumeMl) { item in
                Text(item.label(in: unitSystem)).font(.callout).tag(item.volumeMl)
            }
        }
    }

    private var strengthPicker: some View {
        Picker(String(localized: "addDrink.strength"), selection: $abv) {
            ForEach(abvValues, id: \.self) { value in
                Text(String(format: "%.1f%%", value * 100)).font(.callout).tag(value)
            }
        }
    }

    private var countPicker: some View {
        Picker(String(localized: "addDrink.amount"), selection: $count) {
            ForEach(1...10, id: \.self) { n in
                Text("\(n)×").font(.callout).tag(n)
            }
        }
    }
}

private struct ServingPreviewHost: View {
    @State var volumeMl = 500.0
    @State var abv = 0.05
    @State var count = 1

    var body: some View {
        NavigationStack {
            Form {
                DrinkServingSection(
                    volumeMl: $volumeMl, abv: $abv, count: $count,
                    volumeOptions: DrinkServingOptions.volumeOptions(
                        for: .beer, in: .metric, keeping: volumeMl),
                    abvValues: DrinkServingOptions.abvValues(for: .beer, stepPermille: 5),
                    unitSystem: .metric
                )
            }
            .brandListBackground()
        }
    }
}

#Preview("Light") { ServingPreviewHost() }
#Preview("Dark") { ServingPreviewHost().preferredColorScheme(.dark) }
#Preview("AX5") { ServingPreviewHost().dynamicTypeSize(.accessibility5) }
#Preview("Kept foreign volume") { ServingPreviewHost(volumeMl: 345) }
