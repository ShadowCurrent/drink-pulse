import SwiftUI
import SwiftData

/// Custom Name entry with tap-to-autocomplete suggestions, sourced from the
/// user's own prior `ConsumptionEvent.customName` history (on-device only,
/// no hardcoded list). Shared by the Add (`DrinkDetailInputView`) and Edit
/// (`EditEventView`) forms so both screens get identical suggestion behavior.
struct CustomNameSuggestionSection: View {
    @Binding var customName: String

    @Query(filter: #Predicate<ConsumptionEvent> { $0.customName != nil })
    private var eventsWithCustomName: [ConsumptionEvent]

    @FocusState private var isFieldFocused: Bool

    /// Gated on focus so the list disappears once the user taps elsewhere,
    /// rather than staying visible after the field loses first-responder.
    private var suggestions: [String] {
        let names = eventsWithCustomName.compactMap(\.customName)
        return CustomNameSuggestionFilter.suggestions(for: customName, in: names)
    }

    var body: some View {
        Section(String(localized: "editDrink.customName")) {
            TextField(String(localized: "editDrink.customNamePlaceholder"), text: $customName)
                .autocorrectionDisabled()
                .focused($isFieldFocused)
                .accessibilityLabel(String(localized: "editDrink.customName"))

            if isFieldFocused && !suggestions.isEmpty {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        customName = suggestion
                        isFieldFocused = false
                    } label: {
                        Label(suggestion, systemImage: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel(
                        Text("\(String(localized: "editDrink.customNameSuggestion")): \(suggestion)")
                    )
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var customName = "Craft"

    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(
        ConsumptionEvent(volumeMl: 330, abv: 0.06, category: .beer, icon: "🍺", customName: "Craft IPA")
    )
    container.mainContext.insert(
        ConsumptionEvent(volumeMl: 175, abv: 0.12, category: .wine, icon: "🍷", customName: "Sunday Brunch Cava")
    )

    return Form {
        CustomNameSuggestionSection(customName: $customName)
    }
    .modelContainer(container)
}
