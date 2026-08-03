import SwiftUI

struct GuidelinePickerSheet: View {
    @Binding var selection: GuidelineChoice
    let sex: BiologicalSex
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // `\.self` is a stable, cheap identity here: the enum is an immutable
                // String-raw-valued CaseIterable, not the mutable value the A1 identity
                // check flags.
                ForEach(GuidelineChoice.selectable, id: \.self) { choice in
                    GuidelineChoiceRow(
                        choice: choice,
                        sex: sex,
                        isSelected: selection == choice
                    ) {
                        selection = choice
                        dismiss()
                    }
                }
            }
            .navigationTitle(String(localized: "settings.section.guideline"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .fraction(0.95)])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    @Previewable @State var selection: GuidelineChoice = .who
    GuidelinePickerSheet(selection: $selection, sex: .male)
}
