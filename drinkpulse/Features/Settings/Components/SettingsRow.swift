import SwiftUI

/// Label + control row that stacks vertically at accessibility text sizes.
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } else {
            HStack {
                Text(label)
                Spacer()
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

extension View {
    func cardRow() -> some View {
        self.padding(.horizontal, 16).padding(.vertical, 12)
    }
}
