# 0007 — Execution Journal

_Append-only. Newest entries at the bottom._

---

## 2026-05-19 — Initial implementation

**Open questions resolved (defaults applied):**
- Q1: Custom cards — replaced `Form` in `SettingsView` with `ScrollView + VStack + .dpGlassCard()` sections.
- Q2: `#available(iOS 26, *)` conditional — `DPGlassModifier` uses `glassEffect(.regular, in:)` on iOS 26+ and `.ultraThinMaterial + border + shadow` fallback on iOS 18.
- Q3: Design corner radii — chip: 16, card: 22, sheet: 28.

**Files created:**
- `DesignSystem/DPGlass.swift` — `dpGlassCard(_:)` modifier with `DPGlassSize` enum; iOS 26 glassEffect + iOS 18 material fallback.
- `DesignSystem/DPSemanticColors.swift` — `Color.dpRiskLow / .dpRiskModerate / .dpRiskHigh` via Asset Catalog.
- `DesignSystem/DPLargeTitle.swift` — `dpLargeTitle()` modifier: 28pt bold, kerning -0.6.
- `DesignSystem/DPArcProgress.swift` — 240° arc gauge with track + fill + accessibility label.
- `Assets.xcassets/RiskLow.colorset/` — green, light r=0.22 g=0.56 b=0.24 / dark r=0.30 g=0.75 b=0.32.
- `Assets.xcassets/RiskModerate.colorset/` — amber, light r=1.00 g=0.56 b=0.00 / dark r=1.00 g=0.68 b=0.20.
- `Assets.xcassets/RiskHigh.colorset/` — red, light r=0.90 g=0.22 b=0.21 / dark r=1.00 g=0.33 b=0.30.
- `Domain/GuidelineChoice+Display.swift` — shared `displayName` and `thresholdSummary(for:)` extension (deduplication of private extensions in SettingsView and GuidelineStep).
- `Features/Settings/Components/GuidelinePickerSheet.swift` — extracted from SettingsView to keep line count under 300.

**Files modified:**
- `Features/Settings/SettingsView.swift` — replaced `Form` with `ScrollView + dpGlassCard()` section cards; removed duplicate GuidelineChoice private extension.
- `Features/Onboarding/Components/GuidelineStep.swift` — removed duplicate `thresholdSummary(for:)` (now in GuidelineChoice+Display.swift); kept `onboardingName` private.
- `Localizable.xcstrings` — added `arc.progress.label` en/de/pl.

**Deviation from plan:** `GuidelineChoice+Display.swift` added to `Domain/` to resolve a private-extension duplication that the GuidelinePickerSheet extraction forced. Not in the original file table; noted here.

**Build:** clean. **Tests:** 73/73 passing.

---

## 2026-05-20 — Q3 corner radius correction

Open questions were answered after initial implementation. Q1 and Q2 matched the defaults already shipped. Q3 answer: **HIG values** — owner prefers chip=14 / card=24 / sheet=20 over design-handoff values (16/22/28).

Updated `DPGlass.swift` `DPGlassSize.cornerRadius`. Build clean.
