import SwiftUI

/// Two tiles side by side, stacked at accessibility sizes (plan 0046, D0046-4). A Dynamic Type
/// branch, not `ViewThatFits`: the accessibility audit flags every text of a `ViewThatFits`
/// as `dynamicType` (it measures the alternative that is not shown; plan 0046 Task 7).
struct TilePair<First: View, Second: View>: View {
    @ViewBuilder var first: First
    @ViewBuilder var second: Second

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 12) {
                first
                second
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                first.frame(maxHeight: .infinity)
                second.frame(maxHeight: .infinity)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    TilePair {
        MetricTile(title: "Calories", systemImage: "flame.fill", tint: .orange, value: "224 kcal")
    } second: {
        MetricTile(title: "Drinks", systemImage: "wineglass.fill", tint: .pink, value: "2")
    }
    .padding()
    .brandBackground()
}
