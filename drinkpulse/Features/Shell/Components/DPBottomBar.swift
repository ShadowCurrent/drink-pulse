import SwiftUI

struct DPBottomBar: View {
    let selected: AppTab
    let onSelect: (AppTab) -> Void
    let onAddDrink: () -> Void
    @Environment(\.dpTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            tabPill
            AddDrinkFAB(gradient: theme.gradient, primary: theme.primary, action: onAddDrink)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    // MARK: - Pill

    @ViewBuilder
    private var tabPill: some View {
        if #available(iOS 26, *) {
            pillContent
                .glassEffect(.regular, in: Capsule())
        } else {
            pillContent
                .background { fallbackPillBackground }
        }
    }

    private var pillContent: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabItemButton(
                    tab: tab,
                    isSelected: selected == tab,
                    activeColor: theme.primary
                ) { onSelect(tab) }
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
    }

    private var fallbackPillBackground: some View {
        let border: Color = colorScheme == .dark
            ? .white.opacity(0.14) : .white.opacity(0.75)
        let shadowOpacity: Double = colorScheme == .dark ? 0.40 : 0.10
        return Capsule()
            .fill(.ultraThinMaterial)
            .overlay { Capsule().strokeBorder(border, lineWidth: 0.5) }
            .shadow(color: .black.opacity(shadowOpacity), radius: 22, y: 4)
    }
}

// MARK: - Tab item button

private struct TabItemButton: View {
    let tab: AppTab
    let isSelected: Bool
    let activeColor: Color
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 1) {
                Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                    .font(.system(size: 22))
                    .frame(height: 26)
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? activeColor : .secondary)
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .frame(minWidth: 54)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(activeColor.opacity(colorScheme == .dark ? 0.16 : 0.12))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .accessibilityLabel(isSelected ? "\(tab.label), selected" : tab.label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Gradient FAB

private struct AddDrinkFAB: View {
    let gradient: LinearGradient
    let primary: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .overlay(alignment: .top) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.34), .clear],
                                    startPoint: .top, endPoint: .center
                                )
                            )
                            .padding(1.5)
                    }
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 64, height: 64)
            .shadow(color: primary.opacity(0.40), radius: 22, y: 6)
            .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
        }
        .buttonStyle(SpringButtonStyle())
        .accessibilityLabel(String(localized: "addDrink.title"))
    }
}

private struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.91 : 1.0)
            .animation(.spring(response: 0.12, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Ember light") {
    ZStack(alignment: .bottom) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        VStack { Spacer(); Text("Content").padding() }
        DPBottomBar(selected: .home, onSelect: { _ in }, onAddDrink: {})
    }
}

#Preview("Iris dark") {
    ZStack(alignment: .bottom) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        DPBottomBar(selected: .insights, onSelect: { _ in }, onAddDrink: {})
            .environment(\.dpTheme, .iris)
    }
    .preferredColorScheme(.dark)
}
