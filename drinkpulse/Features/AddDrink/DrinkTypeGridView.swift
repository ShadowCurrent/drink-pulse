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
        .navigationTitle(String(localized: "Add Drink"))
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: DrinkTypePreset.self) { preset in
            DrinkDetailInputView(preset: preset)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "Cancel")) { dismiss() }
            }
        }
    }
}

struct DrinkTypeTile: View {
    let preset: DrinkTypePreset

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: preset.icon)
                .font(.system(size: 34))
                .foregroundStyle(.tint)
            Text(preset.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        DrinkTypeGridView()
    }
}
