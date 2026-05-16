import SwiftUI
import SwiftData

private extension DrinkCategory {
    var icon: String {
        switch self {
        case .beer: "mug.fill"
        case .wine: "wineglass.fill"
        case .spirits: "drop.fill"
        case .cocktail: "cup.and.saucer.fill"
        case .custom: "wineglass"
        }
    }

    var label: String {
        switch self {
        case .beer: String(localized: "Beer")
        case .wine: String(localized: "Wine")
        case .spirits: String(localized: "Spirits")
        case .cocktail: String(localized: "Cocktail")
        case .custom: String(localized: "Custom")
        }
    }
}

struct AddDrinkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: DrinkCategory = .beer
    @State private var volumeMlText = "500"
    @State private var abvPercentText = "5.0"
    @State private var notes = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && (Double(volumeMlText) ?? 0) > 0
            && (Double(abvPercentText) ?? -1) >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Drink")) {
                    TextField(String(localized: "Name"), text: $name)
                        .textInputAutocapitalization(.words)

                    Picker(String(localized: "Category"), selection: $category) {
                        ForEach(DrinkCategory.allCases, id: \.self) { cat in
                            Text(cat.label).tag(cat)
                        }
                    }
                }

                Section(String(localized: "Serving")) {
                    HStack {
                        Text(String(localized: "Volume"))
                        Spacer()
                        TextField("500", text: $volumeMlText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("ml")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(String(localized: "Strength"))
                        Spacer()
                        TextField("5.0", text: $abvPercentText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }
                }

                Section(String(localized: "Notes")) {
                    TextField(String(localized: "Optional"), text: $notes, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .navigationTitle(String(localized: "Log Drink"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        guard
            let volumeMl = Double(volumeMlText),
            let abvPercent = Double(abvPercentText),
            volumeMl > 0,
            abvPercent >= 0
        else { return }

        let event = ConsumptionEvent(
            volumeMl: volumeMl,
            abv: abvPercent / 100,
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            icon: category.icon
        )
        modelContext.insert(event)
        dismiss()
    }
}

#Preview {
    AddDrinkView()
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self, GuidelineProfile.self],
            inMemory: true
        )
}
