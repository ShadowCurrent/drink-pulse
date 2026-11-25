import SwiftUI

/// Step heading for About You, Your Guideline and Apple Health: a rounded bold large title (the
/// app's heading voice, `BrandTypography`) over a secondary message (D0048-10).
struct OnboardingHeading: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.body)
                .foregroundStyle(Color.dpSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    OnboardingHeading(title: "About You",
                      message: "Some guidelines set different limits for women and men.")
        .padding()
}
