import SwiftUI

/// A Recent drink: name over "volume · strength" in the user's unit system. The serving is what
/// tells two "Beer" rows apart, so it stays (round 22). At accessibility sizes volume and
/// strength go on their own lines, and no-break spaces keep each value together.
struct RecentDrinkRow: View {
    let drink: RecentDrink
    let unitSystem: UnitSystem

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var title: String {
        drink.customName ?? DrinkTypePreset.preset(for: drink.category).name
    }

    private var volumeText: String { unitSystem.servingVolumeLabel(drink.volumeMl).nonBreaking }
    private var strengthText: String { String(format: "%.1f%%", drink.abv * 100) }

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        Text(volumeText)
                        Text(strengthText)
                    } else {
                        Text("\(volumeText) · \(strengthText)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        } icon: {
            DecorativeEmoji(emoji: drink.icon, baseSize: 22, relativeTo: .body)
        }
    }
}

private extension String {
    var nonBreaking: String { replacingOccurrences(of: " ", with: "\u{00A0}") }
}

private let previewDrinks = [
    RecentDrink(category: .beer, icon: "🍺", volumeMl: 660, abv: 0.055, customName: "Hazy IPA"),
    RecentDrink(category: .wine, icon: "🍷", volumeMl: 175, abv: 0.13, customName: nil),
]

#Preview {
    List {
        Section("Recent") {
            ForEach(previewDrinks) { RecentDrinkRow(drink: $0, unitSystem: .metric) }
        }
        .brandRowBackground()
    }
    .brandListBackground()
}

#Preview("Imperial · AX5") {
    List {
        Section("Recent") {
            ForEach(previewDrinks) { RecentDrinkRow(drink: $0, unitSystem: .imperial) }
        }
        .brandRowBackground()
    }
    .brandListBackground()
    .dynamicTypeSize(.accessibility5)
}
