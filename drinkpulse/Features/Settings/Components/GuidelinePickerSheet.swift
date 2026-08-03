import SwiftUI

struct GuidelinePickerSheet: View {
    @Binding var selection: GuidelineChoice
    let sex: BiologicalSex
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                // Titleless section: the navigation title already reads "Guideline",
                // so an uppercase "GUIDELINE" header right beneath it would be that
                // word twice.
                SettingsSection {
                    // `\.self` is a stable, cheap identity here: the enum is an immutable
                    // String-raw-valued CaseIterable, not the mutable value the A1 identity
                    // check flags.
                    ForEach(GuidelineChoice.selectable, id: \.self) { choice in
                        // Each element stays a single subview so the count per element is
                        // constant, mirroring HistoryDaySectionCard. The separator is keyed
                        // off the value, not an enumerated index (finding A1-3).
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
