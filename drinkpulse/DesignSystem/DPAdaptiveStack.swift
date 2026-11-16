import SwiftUI

/// Lays its content out side by side at regular text sizes and stacked at the accessibility
/// text sizes. This is the pattern `EventRow` uses, extracted once so other screens share it.
///
/// `AnyLayout` switches the container without destroying the state of the subviews.
struct DPAdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Vertical alignment of the side-by-side layout.
    var verticalAlignment: VerticalAlignment = .center
    /// Horizontal alignment of the stacked layout.
    var horizontalAlignment: HorizontalAlignment = .leading
    var spacing: CGFloat?
    @ViewBuilder var content: () -> Content

    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: horizontalAlignment, spacing: spacing))
            : AnyLayout(HStackLayout(alignment: verticalAlignment, spacing: spacing))
    }

    var body: some View {
        layout {
            content()
        }
    }
}

private struct DPAdaptiveStackSample: View {
    var body: some View {
        DPAdaptiveStack(spacing: 12) {
            Text(verbatim: "Calories")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: .rect(cornerRadius: 12))
            Text(verbatim: "Drinks")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: .rect(cornerRadius: 12))
        }
        .padding()
    }
}

#Preview("Regular") {
    DPAdaptiveStackSample()
}

#Preview("Accessibility 5") {
    DPAdaptiveStackSample()
        .dynamicTypeSize(.accessibility5)
}
