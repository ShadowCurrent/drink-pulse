import SwiftUI

// Rounded voice (owner choice 2026-11-20, "headings"): SF Rounded on figures, large navigation
// titles and card titles; everything else stays default SF. HIG Typography: minimise typefaces —
// `.rounded` is the same SF family, so Dynamic Type, Bold Text and metrics stay system-managed.
// Figures use `.fontDesign(.rounded)` + `.monospacedDigit()` inline; there is no helper.

/// A card's title (GroupBox label). The rounded design is part of the font itself, so it does
/// not depend on how a GroupBox style passes fonts to its label.
struct CardTitle: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }

    var body: some View {
        Text(text).font(.system(.headline, design: .rounded))
    }
}

extension View {
    /// Navigation title with a rounded large form. `navigationTitle` stays: the system uses it for
    /// accessibility, the back button and the inline title. `.largeTitle` placement replaces only
    /// the large title's view (SwiftUI docs, `ToolbarItemPlacement.largeTitle`).
    func brandNavigationTitle(_ title: LocalizedStringKey) -> some View {
        navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .largeTitle) {
                    Text(title)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
    }
}

#Preview {
    NavigationStack {
        List {
            Section { Text(verbatim: "Row") } header: { CardTitle("Card title") }
        }
        .brandNavigationTitle("Today")
    }
}
