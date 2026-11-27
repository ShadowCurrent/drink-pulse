import SwiftUI

/// Period switch (plan 0046, D0046-8; prototype round 21): segmented at regular sizes; a menu at
/// accessibility sizes, whose label grows with Dynamic Type (a segmented control's labels do
/// not). A separate `View` struct: the preview thunk could not type-check a `@ViewBuilder`
/// property (round 21 note).
struct InsightsPeriodPicker: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var period: InsightsPeriod

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            picker
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            picker.pickerStyle(.segmented)
        }
    }

    private var picker: some View {
        Picker(String(localized: "insights.section.period"), selection: $period) {
            ForEach(InsightsPeriod.allCases, id: \.self) { p in
                Text(p.localizedLabel).tag(p)
            }
        }
    }
}

#Preview("Segmented") {
    @Previewable @State var period = InsightsPeriod.week
    InsightsPeriodPicker(period: $period).padding()
}

#Preview("Menu · AX5") {
    @Previewable @State var period = InsightsPeriod.month
    InsightsPeriodPicker(period: $period)
        .padding()
        .dynamicTypeSize(.accessibility5)
}
