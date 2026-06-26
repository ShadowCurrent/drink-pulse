import SwiftUI

/// Delete-confirmation popover for the Edit screen, anchored to the trash
/// toolbar button (the arrow points at it). Forced to stay a popover on
/// compact/iPhone via `presentationCompactAdaptation` — otherwise iOS
/// collapses it into a bottom sheet and the anchor is lost.
struct DeleteConfirmationPopover: View {
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(String(localized: "editDrink.deleteConfirm.title"))
                .font(.headline)
            Text(String(localized: "editDrink.deleteConfirm.message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(role: .destructive, action: onConfirm) {
                Label(String(localized: "action.delete"), systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .accessibilityIdentifier("confirmDeleteButton")
        }
        .padding()
        .frame(width: 260)
        .presentationCompactAdaptation(.popover)
    }
}

#Preview {
    DeleteConfirmationPopover(onConfirm: {})
}
