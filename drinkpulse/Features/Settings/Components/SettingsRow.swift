import SwiftUI

/// Label + control row for use inside a List Section.
/// Horizontal insets are provided by the List; vertical padding is applied here.
struct SettingsRow<Content: View>: View {
    let label: String
    let content: Content
    @Environment(\.dynamicTypeSize) private var typeSize

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack {
                Text(label)
                Spacer()
                content
            }
        }
    }
}
