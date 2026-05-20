# 0008 — Execution Journal

_Append-only. Newest entries at the bottom._

---

## 2026-05-20 — Initial implementation

**Open questions resolved before freeze:**
- Q1: System bar — no tab-bar custom background; tint propagates via root `.tint()`.
- Q2: sRGB hex constants (pre-converted from oklch via Python script; see plan table).
- Q3: Settings → Appearance section (default).
- Q4: Ember default.
- Scope narrowed: card backgrounds stay system glass; theme affects only primary tint + FAB gradient.

**Files created:**
- `DesignSystem/DPTheme.swift` — enum with `primary`, `gradientStart`, `gradientEnd`, `gradient`, `displayName`. Pre-converted sRGB constants inline.
- `DesignSystem/DPTheme+Environment.swift` — `@Entry var dpTheme: DPTheme = .ember`.
- `Features/Settings/Components/AppearanceCard.swift` — theme swatch picker (3 `ThemeSwatch` circles) + light/dark/system mode picker.
- `Features/Settings/Components/SettingsRow.swift` — extracted from `SettingsView.swift` (was `private`; made internal so `AppearanceCard` can use it).
- `drinkpulseTests/DPThemeTests.swift` — 6 tests (primary distinct, gradient endpoints distinct, rawValue round-trip, invalid rawValue nil, displayName non-empty, allCases count).

**Files modified:**
- `drinkpulseApp.swift` — added `@AppStorage("dp_theme")`, `@AppStorage("dp_color_scheme")`; root `Group` now applies `.environment(\.dpTheme, theme)`, `.tint(theme.primary)`, `.preferredColorScheme(preferredColorScheme)`.
- `Features/Settings/SettingsView.swift` — added "Appearance" section at top; removed `SettingsRow` and `cardRow` (now in `SettingsRow.swift`).
- `Localizable.xcstrings` — added 9 keys: `theme.ember/forest/iris`, `settings.section.appearance`, `settings.appearance.theme`, `settings.appearance.mode`, `settings.appearance.mode.system/light/dark` (en/de/pl).
- `drinkpulse.xcodeproj/project.pbxproj` — registered `DPThemeTests.swift` in test target.

**Deviation from plan:** `SettingsRow` extracted to `Components/SettingsRow.swift` to keep `SettingsView.swift` under 300 lines. Not in the original file table; noted here.

**Build:** clean. **Tests:** 127/127 passing (10 suites, +6 DPTheme tests).
