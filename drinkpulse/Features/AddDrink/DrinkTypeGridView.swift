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
///
/// A pushed step passes no `cancel`: it shows Back and Save only (HIG Sheets, multi-step flow:
/// avoid Cancel, Back and Done together). A leading Cancel beside the system Back button also made
/// a cancelled interactive pop drop the Back button on iOS 27.
struct SheetActionsModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let cancel: (() -> Void)?
    let save: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .toolbar {
                if !dynamicTypeSize.isAccessibilitySize {
                    if let cancel {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(role: .cancel, action: cancel)
                        }
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
                        if let cancel {
                            Button(action: cancel) {
                                Text(String(localized: "action.cancel")).frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.primary)
                        }
                    }
                    .padding()
                    // Opaque, so rows scrolling under the bar never show through the translucent
                    // buttons behind their labels (audit contrast finding, plan 11-18).
                    .background(.background)
                }
            }
    }
}

extension View {
    func sheetActions(cancel: (() -> Void)?, save: (() -> Void)? = nil) -> some View {
        modifier(SheetActionsModifier(cancel: cancel, save: save))
    }
}

#Preview {
    AddDrinkView()
}
