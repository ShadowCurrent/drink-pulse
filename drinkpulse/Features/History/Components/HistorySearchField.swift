import SwiftUI

/// Inline search row for the History list (HIG "search as an inline field"
/// for filtering a single view). Built from standard controls because
/// SwiftUI's `searchable` cannot be placed inside content on iOS.
///
/// Shows the All / Named / Unnamed scope picker while the field is focused
/// or a filter is active, and a Cancel button while focused. Cancel clears
/// the text, resets the scope to All and dismisses the keyboard.
///
/// The field uses `axis: .vertical`: the single-line `TextField` fails the
/// XCUITest accessibility audit with `textClipped` on iOS 27.2, the
/// vertical-axis field does not (plan-0039 execution log).
struct HistorySearchField: View {
    @Binding var text: String
    @Binding var scope: HistorySearchScope

    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var showsScopes: Bool {
        isFocused || HistorySearchFilter(text: text, scope: scope).isActive
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                field
                if isFocused {
                    Button(String(localized: "action.cancel"), action: cancel)
                        // The ember accent fails the 4.5:1 text contrast audit here.
                        .foregroundStyle(.primary)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            if showsScopes {
                scopePicker
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .default, value: isFocused)
        .animation(reduceMotion ? nil : .default, value: showsScopes)
        .onChange(of: text) { _, newValue in
            // The vertical-axis field inserts a newline on Return; treat it as
            // "search": drop the newline and dismiss the keyboard.
            guard newValue.contains(where: \.isNewline) else { return }
            text = newValue.filter { !$0.isNewline }
            isFocused = false
        }
    }

    private var field: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(String(localized: "history.search.prompt"), text: $text, axis: .vertical)
                .lineLimit(1...3)
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier("history.search.field")
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "history.search.clear"))
                .accessibilityIdentifier("history.search.clear")
            }
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 44)
        .background(Color(.tertiarySystemFill), in: Capsule())
    }

    private var scopePicker: some View {
        Picker(String(localized: "history.search.scope.picker"), selection: $scope) {
            ForEach(HistorySearchScope.allCases) { scope in
                Text(scope.label).tag(scope)
            }
        }
        .pickerStyle(.segmented)
    }

    private func cancel() {
        text = ""
        scope = .all
        isFocused = false
    }
}

#Preview {
    @Previewable @State var text = "guin"
    @Previewable @State var scope = HistorySearchScope.all
    HistorySearchField(text: $text, scope: $scope)
        .padding()
}
