import SwiftUI

struct PeriodPicker: View {
    @Binding var period: InsightsPeriod

    var body: some View {
        Picker(String(localized: "insights.section.period"), selection: $period) {
            ForEach(InsightsPeriod.allCases, id: \.self) { p in
                Text(p.localizedLabel).tag(p)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(String(localized: "insights.section.period"))
    }
}

#Preview {
    @Previewable @State var period: InsightsPeriod = .week
    PeriodPicker(period: $period)
        .padding()
}
