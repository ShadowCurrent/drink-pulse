import SwiftUI

/// One selectable guideline, used by **both** the Settings guideline picker and
/// the onboarding guideline step.
///
/// The row was previously inlined in each of those screens, and the two copies had
/// diverged three ways — different name source, different checkmark symbol, and a
/// selected-state accessibility trait present in one and missing in the other
/// (findings A7-2 / C14-4). Keeping exactly one definition is what makes that
/// divergence structurally impossible rather than merely fixed once.
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
                    // Hidden from accessibility on purpose: the `.isSelected` trait
                    // below now carries this meaning, so exposing the glyph too would
                    // make VoiceOver read a symbol description *and* the state.
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)
                        .accessibilityHidden(true)
                }
            }
            // Matches SettingsRow's row padding (plan-0027). A row inside a List
            // inherited the platform's default row insets; inside a dpGlassCard's
            // VStack(spacing: 0) it does not, and collapses to font-metrics-only
            // height (the plan-0038 regression recorded in HistoryDaySectionCard).
            //
            // It must sit INSIDE the content shape, or the padded strip is visible
            // but not tappable — the dead-padding defect finding C14-1 fixes in
            // History. Do not move it after .buttonStyle(.plain).
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // C14-4: without this the Settings picker conveyed selection through an
        // unlabelled glyph alone, so VoiceOver announced the guideline with no state.
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
