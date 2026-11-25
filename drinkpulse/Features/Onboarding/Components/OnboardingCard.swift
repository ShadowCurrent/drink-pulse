import SwiftUI

/// Card surface for the onboarding step controls: `BrandSurface` at `CardMetrics.cornerRadius`,
/// with no padding of its own so rows (`OnboardingChoiceRow`, the Health toggles) reach the edges.
/// No material on content (HIG Materials, D0048-10).
struct OnboardingCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .background { BrandSurface() }
            .clipShape(.rect(cornerRadius: CardMetrics.cornerRadius))
    }
}

#Preview {
    OnboardingCard {
        Text(verbatim: "Row one").padding(CardMetrics.padding)
        Divider()
        Text(verbatim: "Row two").padding(CardMetrics.padding)
    }
    .padding()
}
