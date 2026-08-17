import SwiftUI

struct GuidelineChoiceRow: View {
    let choice: GuidelineChoice
    let sex: BiologicalSex
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
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
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("guidelineChoiceRow.\(choice.rawValue)")
    }
}

#Preview {
    VStack(spacing: 0) {
        GuidelineChoiceRow(choice: .who, sex: .male, isSelected: true, onSelect: {})
        Divider()
        GuidelineChoiceRow(choice: .de, sex: .male, isSelected: false, onSelect: {})
    }
    .padding()
}
