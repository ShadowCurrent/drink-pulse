import SwiftUI

/// Two tiles side by side, stacked when the text no longer fits (plan 0046, D0046-4).
/// `ViewThatFits` measures instead of branching on the Dynamic Type size.
struct TilePair<First: View, Second: View>: View {
    @ViewBuilder var first: First
    @ViewBuilder var second: Second

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                first.frame(maxHeight: .infinity)
                second.frame(maxHeight: .infinity)
            }
            .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 12) {
                first
                second
            }
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
