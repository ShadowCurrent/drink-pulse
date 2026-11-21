import SwiftUI

/// A small card: icon + title as the GroupBox label, a large value as content (plan 0046,
/// D0046-4; prototype `CardComponents`). Replaces `DPChip` and `StreakCard`. Icons keep their
/// natural colour, one colour per concept.
struct MetricTile: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    let title: String
    let systemImage: String
    let tint: Color
    /// `LocalizedStringKey` so `^[n day](inflect: true)` gets automatic grammar agreement.
    let value: LocalizedStringKey
    var detail: String? = nil
    /// One quiet bounce of the icon the first time the tile appears (alcohol-free streak only).
    var celebrates: Bool = false

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .contentTransition(.numericText())
                    .font(.title2.bold())
                    .fontDesign(.rounded)
                    .monospacedDigit()
                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Color.dpSecondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label {
                Text(title).fontDesign(.rounded)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .symbolEffect(.bounce, value: hasAppeared)
            }
            .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
        // Short delay so the bounce is seen after the screen settles. `@State` survives tab
        // switches, so it plays once per launch, not on every visit.
        .task {
            guard celebrates, !DPMotion.isReduced(system: reduceMotion), !hasAppeared else { return }
            // Cancellation is the only error `Task.sleep` throws; a cancelled task skips the bounce.
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            hasAppeared = true
        }
    }
}

#Preview("Tiles") {
    ScrollView {
        TilePair {
            MetricTile(title: "Calories", systemImage: "flame.fill", tint: .orange, value: "224 kcal")
        } second: {
            MetricTile(title: "Drinks", systemImage: "wineglass.fill", tint: .pink, value: "2")
        }
        .padding()
    }
    .brandBackground()
}

#Preview("Tiles · AX5") {
    ScrollView {
        TilePair {
            MetricTile(title: "Alcohol-Free Streak", systemImage: "trophy.fill", tint: .purple,
                       value: "^[0 day](inflect: true)", detail: "Start one tomorrow")
        } second: {
            MetricTile(title: "Alcohol-Free This Month", systemImage: "moon.fill", tint: .teal,
                       value: "^[12 day](inflect: true)")
        }
        .padding()
    }
    .brandBackground()
    .dynamicTypeSize(.accessibility5)
}
