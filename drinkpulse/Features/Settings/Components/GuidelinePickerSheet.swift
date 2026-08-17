import SwiftUI

struct GuidelinePickerSheet: View {
    @Binding var selection: GuidelineChoice
    let sex: BiologicalSex
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                SettingsSection {
                    ForEach(GuidelineChoice.selectable, id: \.self) { choice in
                        VStack(spacing: 0) {
                            if choice != GuidelineChoice.selectable.first {
                                Divider()
                            }
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
                }
                .padding()
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
