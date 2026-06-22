import SwiftUI

struct GuidelinePickerSheet: View {
    @Binding var selection: GuidelineChoice
    let sex: BiologicalSex
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(GuidelineChoice.allCases.filter { $0 != .custom }, id: \.self) { choice in
                    Button {
                        selection = choice
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(choice.displayName)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Text(choice.thresholdSummary(for: sex))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selection == choice {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
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
