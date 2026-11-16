import SwiftUI

struct DrinkTypeGridView: View {
    let dismissSheet: DismissAction

    @State private var selection: DrinkTypePreset?

    var body: some View {
        DrinkTypeGrid { selection = $0 }
            .navigationTitle(String(localized: "addDrink.title"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selection) { preset in
                DrinkDetailInputView(preset: preset, dismissSheet: dismissSheet)
            }
            .sheetActions(cancel: { dismissSheet() })
    }
}

/// The navigation bar does not scale its buttons with Dynamic Type, so at accessibility sizes the
/// sheet actions leave it and move into a bottom bar whose buttons wrap. At regular sizes they stay
/// in the navigation bar. The button labels are the same in both places.
struct SheetActionsModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let cancel: () -> Void
    let save: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .toolbar {
                if !dynamicTypeSize.isAccessibilitySize {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "action.cancel"), action: cancel)
                    }
                    if let save {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(String(localized: "action.save"), action: save)
                        }
                    }
                }
            }
            .safeAreaBar(edge: .bottom) {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 8) {
                        if let save {
                            Button(action: save) {
                                Text(String(localized: "action.save")).frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Button(action: cancel) {
                            Text(String(localized: "action.cancel")).frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
    }
}

extension View {
    func sheetActions(cancel: @escaping () -> Void, save: (() -> Void)? = nil) -> some View {
        modifier(SheetActionsModifier(cancel: cancel, save: save))
    }
}

#Preview {
    AddDrinkView()
}
