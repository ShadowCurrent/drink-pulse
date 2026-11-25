import SwiftUI
import SwiftData

struct CustomNameSuggestionSection: View {
    @Binding var customName: String

    @Query(filter: #Predicate<ConsumptionEvent> { $0.customName != nil })
    private var eventsWithCustomName: [ConsumptionEvent]

    @FocusState private var isFieldFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var suggestions: [String] {
        let names = eventsWithCustomName.compactMap(\.customName)
        return CustomNameSuggestionFilter.suggestions(for: customName, in: names)
    }

    var body: some View {
        Section {
            nameField
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
        } header: {
            // Contrast-safe ink on the Frost tint (plan 0043: system grey is 3.2:1).
            Text(String(localized: "editDrink.customName")).foregroundStyle(Color.dpSecondaryText)
        }
    }

    /// A vertical-axis field wraps its placeholder at accessibility sizes; regular sizes keep
    /// the single-line field.
    @ViewBuilder
    private var nameField: some View {
        if dynamicTypeSize.isAccessibilitySize {
            TextField(String(localized: "editDrink.customNamePlaceholder"), text: $customName,
                      axis: .vertical)
        } else {
            TextField(String(localized: "editDrink.customNamePlaceholder"), text: $customName)
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
