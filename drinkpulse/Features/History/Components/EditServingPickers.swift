import SwiftUI

/// The serving row of the Edit screen: three side-by-side wheel pickers
/// (volume, ABV, count). Extracted from `EditEventView` so the parent stays
/// under the file-size ceiling. State stays in the parent; this view only
/// binds to it, so no parent state is widened beyond `private`.
struct EditServingPickers: View {
    @Binding var volumeMl: Double
    @Binding var abvValue: Double
    @Binding var count: Int

    let volumeOptions: [DrinkTypePreset.VolumeOption]
    let abvValues: [Double]
    let unitSystem: UnitSystem

    var body: some View {
        HStack(spacing: 0) {
            Picker(String(localized: "addDrink.volume"), selection: $volumeMl) {
                ForEach(volumeOptions, id: \.volumeMl) { item in
                    Text(item.label(in: unitSystem)).font(.callout).tag(item.volumeMl)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .labelsHidden()

            Picker(String(localized: "addDrink.strength"), selection: $abvValue) {
                ForEach(abvValues, id: \.self) { value in
                    Text(String(format: "%.1f%%", value * 100)).font(.callout).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 88)
            .labelsHidden()

            Picker(String(localized: "addDrink.amount"), selection: $count) {
                ForEach(1 ... 10, id: \.self) { n in
                    Text("\(n)×").font(.callout).tag(n)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 60)
            .labelsHidden()
        }
        .frame(height: 160)
        .listRowInsets(EdgeInsets())
    }
}

#Preview {
    @Previewable @State var volume = 500.0
    @Previewable @State var abv = 0.05
    @Previewable @State var count = 1
    let preset = DrinkTypePreset.preset(for: .beer)
    return Form {
        EditServingPickers(
            volumeMl: $volume,
            abvValue: $abv,
            count: $count,
            volumeOptions: preset.volumes(for: .metric),
            abvValues: preset.abvValues,
            unitSystem: .metric
        )
    }
}
