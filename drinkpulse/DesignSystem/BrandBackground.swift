import SwiftUI

/// Frost tint behind every screen: the grouped background mixed with the accent by
/// `Brand.tintFraction`. Placed with `containerBackground(for: .navigation)`, which fills the
/// enclosing NavigationStack (SwiftUI docs, `ContainerBackgroundPlacement.navigation`).
struct BrandBackdrop: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Color(uiColor: .systemGroupedBackground)
            .mix(with: Brand.accent, by: Brand.tintFraction(scheme: scheme, contrast: contrast))
    }
}

/// Card / row surface on the tinted page: the grouped surface mixed with the accent by
/// `Brand.surfaceFraction`. Shared by cards (`BrandCardStyle`) and List rows.
struct BrandSurface: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Color(uiColor: .secondarySystemGroupedBackground)
            .mix(with: Brand.accent, by: Brand.surfaceFraction(scheme: scheme, contrast: contrast))
    }
}

extension View {
    /// Card screens (Today, Insights): tinted page behind the navigation container.
    func brandBackground() -> some View {
        containerBackground(for: .navigation) { BrandBackdrop() }
    }

    /// `List` / `Form` screens (History, Settings): `scrollContentBackground(.hidden)` removes
    /// the system grey so the navigation container background shows through (SwiftUI docs).
    func brandListBackground() -> some View {
        scrollContentBackground(.hidden)
            .containerBackground(for: .navigation) { BrandBackdrop() }
    }

    /// Row surface matching the cards. Apply to the rows (a `Group` of sections works).
    func brandRowBackground() -> some View { listRowBackground(BrandSurface()) }
}

private struct BrandBackgroundPreview: View {
    var body: some View {
        TabView {
            Tab("Cards", systemImage: "square.grid.2x2") {
                NavigationStack {
                    ScrollView {
                        GroupBox("Card") { Text(verbatim: "Content on the brand surface") }
                            .padding()
                    }
                    .navigationTitle(Text(verbatim: "Cards"))
                    .brandBackground()
                }
            }
            Tab("List", systemImage: "list.bullet") {
                NavigationStack {
                    List {
                        Section("Section") {
                            Text(verbatim: "Row one")
                            Text(verbatim: "Row two")
                        }
                        .brandRowBackground()
                    }
                    .navigationTitle(Text(verbatim: "List"))
                    .brandListBackground()
                }
            }
        }
    }
}

#Preview("Light") { BrandBackgroundPreview() }
#Preview("Dark") { BrandBackgroundPreview().preferredColorScheme(.dark) }
