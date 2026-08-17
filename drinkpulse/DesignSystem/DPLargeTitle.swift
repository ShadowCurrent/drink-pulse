import SwiftUI

extension View {
    func dpLargeTitle() -> some View {
        modifier(DPLargeTitleModifier())
    }
}

private struct DPLargeTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 28, weight: .bold))
            .kerning(-0.6)
    }
}

#Preview {
    Text("DrinkPulse")
        .dpLargeTitle()
        .padding()
}
