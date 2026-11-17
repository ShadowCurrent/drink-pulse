import SwiftUI

/// A drink-type emoji drawn as a decorative image instead of as text.
///
/// The emoji on a drink-type tile is a pictogram: the tile's name carries its meaning and the
/// emoji is not read by VoiceOver. As a `Text` it was still treated as text by the accessibility
/// audit, whose text contrast and clipping checks cannot pass for multicolour emoji glyphs (plan
/// 11-18, audit group A11Y-AUDIT-G01). Drawn once into an image with `ImageRenderer` and shown
/// with `Image(decorative:scale:)`, it looks the same, is an unlabelled decorative image to
/// accessibility, and still follows Dynamic Type through a metric scaled like `.largeTitle`.
struct DecorativeEmoji: View {
    @Environment(\.displayScale) private var displayScale
    @ScaledMetric(relativeTo: .largeTitle) private var pointSize: CGFloat = 34

    let emoji: String

    var body: some View {
        if let image = rendered {
            Image(decorative: image, scale: displayScale)
        }
    }

    /// The emoji rasterized at the current point size and screen scale; nil only if the renderer
    /// produces no image, in which case the tile shows its name alone.
    private var rendered: CGImage? {
        let renderer = ImageRenderer(content: Text(emoji).font(.system(size: pointSize)))
        renderer.scale = displayScale
        return renderer.cgImage
    }
}

#Preview {
    HStack(spacing: 16) {
        DecorativeEmoji(emoji: "🍺")
        DecorativeEmoji(emoji: "🥂")
        DecorativeEmoji(emoji: "🫧")
    }
    .padding()
}

#Preview("Accessibility 5") {
    HStack(spacing: 16) {
        DecorativeEmoji(emoji: "🍺")
        DecorativeEmoji(emoji: "🥂")
    }
    .padding()
    .dynamicTypeSize(.accessibility5)
}
