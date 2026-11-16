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

    private var centerLabel: some View {
        Button {
            vm.jumpToNow()
        } label: {
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
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .frame(minWidth: 0)
        }
        .buttonStyle(.plain)
        .disabled(vm.isCurrentPeriod)
        .accessibilityLabel(vm.friendlyLabel + ", " + vm.rangeLabel)
        .accessibilityHint(vm.isCurrentPeriod ? "" : String(localized: "insights.nav.jumpToNow"))
    }
}

private struct NowPill: View {
    var body: some View {
        Text(String(localized: "insights.nav.now"))
            .font(.caption.weight(.bold))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.tint.opacity(0.18), in: Capsule())
            .foregroundStyle(.tint)
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
