import SwiftUI

/// The drink types in their four family sections (D0047-1), filtered by `query`. Shared by Add
/// Drink step 1 and Edit Drink's type list; the caller builds each row.
///
/// Each section is written out on its own: a `ForEach` over `Section`s crashed the List in the
/// iOS 27.2 preview ("Could not cast UICollectionViewCell to AnyListCollectionViewCell",
/// prototype round 22).
struct DrinkTypeSections<Row: View>: View {
    let query: String
    @ViewBuilder let row: (DrinkTypePreset) -> Row

    var body: some View {
        section(.beerCider, id: "beerCider")
        section(.wine, id: "wine")
        section(.spirits, id: "spirits")
        section(.mixed, id: "mixed")
    }

    @ViewBuilder
    private func section(_ group: DrinkTypeGroup, id: String) -> some View {
        let presets = group.presets(matching: query)
        if !presets.isEmpty {
            Section {
                ForEach(presets) { row($0) }
            } header: {
                Text(group.title).foregroundStyle(Color.dpSecondaryText).accessibilityIdentifier("addDrink.section.\(id)")
            }
        }
    }
}

/// A preset row's label: decorative emoji and name, no serving (round 22). The accessibility
/// label is the name alone.
///
/// - Primary ink is explicit: without it the row text in this sheet's List failed the light
///   and dark `contrast` audits (plan 0047 Task 6).
/// - At accessibility sizes the row shows the name only: the emoji image in a List label icon
///   produced element-less `textClipped` / `dynamicType` findings at AX5, and the name alone
///   carries the meaning.
struct DrinkTypeLabel: View {
    let preset: DrinkTypePreset

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Text(preset.name).foregroundStyle(Color.primary)
        } else {
            Label {
                Text(preset.name).foregroundStyle(Color.primary)
            } icon: {
                DecorativeEmoji(emoji: preset.icon, baseSize: 22, relativeTo: .body)
            }
        }
    }
}

#Preview {
    NavigationStack {
        List {
            DrinkTypeSections(query: "") { preset in
                NavigationLink(value: preset.category) { DrinkTypeLabel(preset: preset) }
                    .brandRowBackground()
            }
        }
        .brandListBackground()
    }
}

#Preview("Search · AX5") {
    NavigationStack {
        List {
            DrinkTypeSections(query: "w") { preset in
                NavigationLink(value: preset.category) { DrinkTypeLabel(preset: preset) }
                    .brandRowBackground()
            }
        }
        .brandListBackground()
    }
    .dynamicTypeSize(.accessibility5)
}
