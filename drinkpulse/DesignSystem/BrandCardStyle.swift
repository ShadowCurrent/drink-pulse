import SwiftUI

nonisolated enum CardMetrics {
    /// Corner radius of the hero and every card (owner choice 2026-11-20, prototype FINDINGS
    /// round 11). The system GroupBox corner is much smaller than inset-grouped List sections, so
    /// card screens looked inconsistent next to list screens. 24 pt matches the iOS 27 List
    /// section corner (measured in renders, within ~1 px); it is not a system-provided value, so
    /// re-check it after each major iOS release.
    static let cornerRadius: CGFloat = 24

    /// Content padding inside a card, as the system GroupBox uses.
    static let padding: CGFloat = 16
}

/// The one card style (`GroupBoxStyle` is the documented customization point): the system
/// anatomy — label above content — on `BrandSurface` with `CardMetrics` corners. No Liquid Glass
/// on content (HIG Materials).
struct BrandCardStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label.font(.headline)
            configuration.content
        }
        .padding(CardMetrics.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            BrandSurface().clipShape(.rect(cornerRadius: CardMetrics.cornerRadius))
        }
    }
}

private struct BrandCardPreview: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GroupBox {
                        Text(verbatim: "42 g").font(.largeTitle).fontDesign(.rounded).monospacedDigit()
                    } label: {
                        CardTitle("This week")
                    }
                    GroupBox(label: CardTitle("Streak")) {
                        Text(verbatim: "3 alcohol-free days")
                    }
                }
                .padding()
            }
            .brandNavigationTitle("Cards")
            .brandBackground()
        }
    }
}

#Preview("Light") { BrandCardPreview() }
#Preview("Dark") { BrandCardPreview().preferredColorScheme(.dark) }
#Preview("AX5") { BrandCardPreview().dynamicTypeSize(.accessibility5) }
