import SwiftUI

struct SettingsRow<Content: View>: View {
    let label: String
    let content: Content
    @Environment(\.dynamicTypeSize) private var typeSize

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        Group {
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
        .padding(.vertical, 10)
    }
}

/// A menu picker whose selected value wraps instead of clipping at accessibility sizes.
///
/// At regular sizes this is the plain `.menu` picker with a hidden label (unchanged). At
/// accessibility sizes the system menu-picker button clips a value that wraps to a second line
/// (owner finding, brief C016), so the same options are shown through a `Menu` whose label wraps.
/// The button keeps the label "Title, Value" that the plain picker exposes.
struct SettingsMenuPicker<Value: Hashable, Options: View>: View {
    let title: String
    let selectionLabel: String
    @Binding var selection: Value
    @ViewBuilder var options: Options
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if typeSize.isAccessibilitySize {
            Menu {
                Picker(title, selection: $selection) { options }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(selectionLabel)
                        .multilineTextAlignment(.leading)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityLabel(Text(verbatim: "\(title), \(selectionLabel)"))
        } else {
            Picker(title, selection: $selection) { options }
                .pickerStyle(.menu)
                .labelsHidden()
        }
    }
}

#Preview {
    ScrollView {
        SettingsSection("PREVIEW") {
            SettingsRow("Volume unit") { Text("ml").foregroundStyle(.secondary) }
            Divider()
            SettingsRow("ABV precision") { Text("0.5%").foregroundStyle(.secondary) }
        }
        .padding()
    }
    .background(Color.dpAmber.opacity(0.04))
}

#Preview("Accessibility 5") {
    @Previewable @State var unit = 1
    ScrollView {
        SettingsSection("PREVIEW") {
            SettingsRow("Alcohol unit") {
                SettingsMenuPicker(title: "Alcohol unit", selectionLabel: "Standard drinks", selection: $unit) {
                    Text(verbatim: "Grams").tag(0)
                    Text(verbatim: "Standard drinks").tag(1)
                }
            }
        }
        .padding()
    }
    .dynamicTypeSize(.accessibility5)
}
