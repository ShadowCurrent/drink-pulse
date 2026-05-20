import SwiftUI

struct DPBottomBar: View {
    let selected: AppTab
    let onSelect: (AppTab) -> Void
    let onAddDrink: () -> Void
    @Environment(\.dpTheme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabItemButton(tab: tab, isSelected: selected == tab) {
                    onSelect(tab)
                }
            }
            Spacer(minLength: 8)
            AddDrinkFAB(gradient: theme.gradient, action: onAddDrink)
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 12)
        .frame(height: 62)
        .background { barBackground }
    }

    private var barBackground: some View {
        Group {
            if #available(iOS 26, *) {
                Rectangle().fill(.bar)
            } else {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(alignment: .top) { Divider() }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Tab item

private struct TabItemButton: View {
    let tab: AppTab
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                    .font(.system(size: 22))
                    .frame(height: 26)
                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isSelected
                ? String(localized: "\(tab.label), selected")
                : tab.label
        )
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - FAB

private struct AddDrinkFAB: View {
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 54, height: 54)
                    .shadow(color: .black.opacity(0.22), radius: 8, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(SpringButtonStyle())
        .accessibilityLabel(String(localized: "addDrink.title"))
    }
}

private struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.91 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack(alignment: .bottom) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack { Spacer(); Text("Content") }
        DPBottomBar(selected: .home, onSelect: { _ in }, onAddDrink: {})
    }
}
