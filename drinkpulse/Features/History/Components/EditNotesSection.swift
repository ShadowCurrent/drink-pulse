import SwiftUI

struct EditNotesSection: View {
    @Binding var notes: String

    private let maxLength = 500

    var body: some View {
        Section {
            TextField(
                String(localized: "editDrink.notesPlaceholder"),
                text: $notes,
                axis: .vertical
            )
            .lineLimit(3...6)
            .onChange(of: notes) { _, new in
                if new.count > maxLength {
                    notes = String(new.prefix(maxLength))
                }
            }
            if notes.count > 400 {
                HStack {
                    Spacer()
                    Text("\(notes.count)/\(maxLength)")
                        .font(.caption2)
                        .foregroundStyle(notes.count >= maxLength ? Color.dpRiskHigh : .secondary)
                }
                .listRowSeparator(.hidden)
            }
        } header: {
            Text(String(localized: "editDrink.notes"))
        }
    }
}

#Preview("Empty") {
    @Previewable @State var notes = ""
    return Form { EditNotesSection(notes: $notes) }
}

#Preview("With text") {
    @Previewable @State var notes = "Had a great evening with friends."
    return Form { EditNotesSection(notes: $notes) }
}
