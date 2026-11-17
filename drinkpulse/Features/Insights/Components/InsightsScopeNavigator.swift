import SwiftUI

struct InsightsScopeNavigator: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Bindable var vm: InsightsViewModel

    var body: some View {
        VStack(spacing: 10) {
            periodPicker
            dateNavigator
        }
    }

    /// Four segments cannot hold their labels at accessibility sizes, so those sizes use a menu.
    @ViewBuilder
    private var periodPicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            periodPickerBase
                .pickerStyle(.menu)
        } else {
            periodPickerBase
                .pickerStyle(.segmented)
        }
    }

    private var periodPickerBase: some View {
        Picker(String(localized: "insights.section.period"), selection: $vm.period) {
            ForEach(InsightsPeriod.allCases, id: \.self) { p in
                Text(p.localizedLabel).tag(p)
            }
        }
        .accessibilityLabel(String(localized: "insights.section.period"))
    }

    private var dateNavigator: some View {
        HStack(spacing: 0) {
            Button {
                vm.navigatePrev()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(vm.isAllTime || vm.activeOffset <= vm.minAllowedOffset)
            .accessibilityLabel(String(localized: "insights.nav.prevPeriod"))

            Spacer(minLength: 0)
            centerLabel
            Spacer(minLength: 0)

            Button {
                vm.navigateNext()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(vm.isAllTime || vm.isCurrentPeriod)
            .accessibilityLabel(String(localized: "insights.nav.nextPeriod"))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .dpGlassCard()
    }

    /// The current period has nothing to jump to, so it shows plain text instead of a disabled
    /// button: a disabled button dims its label below the contrast minimum.
    @ViewBuilder
    private var centerLabel: some View {
        if vm.isCurrentPeriod {
            centerLabelContent
        } else {
            Button {
                vm.jumpToNow()
            } label: {
                centerLabelContent
            }
            .buttonStyle(.plain)
            .accessibilityLabel(vm.friendlyLabel + ", " + vm.rangeLabel)
            .accessibilityHint(String(localized: "insights.nav.jumpToNow"))
        }
    }

    private var centerLabelContent: some View {
        VStack(spacing: 3) {
            DPAdaptiveStack(horizontalAlignment: .center, spacing: 6) {
                Text(vm.friendlyLabel)
                    .font(.subheadline.weight(.semibold))
                if vm.isCurrentPeriod && !vm.isAllTime {
                    NowPill()
                }
            }
            Text(vm.rangeLabel)
                .font(.caption)
                .foregroundStyle(Color.dpSecondaryText)
        }
        .multilineTextAlignment(.center)
        .frame(minWidth: 0)
    }
}

private struct NowPill: View {
    var body: some View {
        Text(String(localized: "insights.nav.now"))
            .font(.caption.weight(.bold))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.tint.opacity(0.18), in: Capsule())
            // Primary text: the accent tint on its own 18% fill is under the contrast minimum.
            .foregroundStyle(.primary)
    }
}

#Preview {
    @Previewable @State var vm = InsightsViewModel.preview
    InsightsScopeNavigator(vm: vm)
        .padding()
}

#Preview("Accessibility 5") {
    @Previewable @State var vm = InsightsViewModel.preview
    InsightsScopeNavigator(vm: vm)
        .padding()
        .dynamicTypeSize(.accessibility5)
}
