import SwiftUI

struct DrinkTypeGridView: View {
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(DrinkTypePreset.all) { preset in
                    NavigationLink(value: preset) {
                        DrinkTypeTile(preset: preset)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(preset.name)
                }
            }
            .padding()
        }
        .navigationTitle(String(localized: "addDrink.title"))
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: DrinkTypePreset.self) { preset in
            DrinkDetailInputView(preset: preset)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "action.cancel")) { dismiss() }
            }
        }
    }
}

struct DrinkTypeTile: View {
    let preset: DrinkTypePreset

    var body: some View {
        VStack(spacing: 18) {
            Text(preset.icon)
                .font(.system(size: 34))
            Text(preset.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        DrinkTypeGridView()
    }
}
