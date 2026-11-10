---
phase: "09"
slug: "swiftui-design-system-modernization"
audited: "2026-11-10"
baseline: "abstract 6-pillar standards + 09-CONTEXT.md decisions (no UI-SPEC.md)"
method: "code-only (native SwiftUI; no screenshots; interaction_capture: false)"
overall_score: 17
max_score: 24
---

# Phase 09 — UI Review

**Overall: 17/24**

| Pillar | Score |
|--------|-------|
| Copywriting | 2/4 |
| Visuals | 3/4 |
| Color | 3/4 |
| Typography | 2/4 |
| Spacing | 3/4 |
| Experience Design | 4/4 |

## Findings

### 1. Copywriting — 2/4 (WARNING)

- `drinkpulse/DesignSystem/DPArcProgress.swift:29` — `arcLabel` returns the hardcoded English string `"\(pctInt)% of daily limit"`. This breaks the project convention that every user-visible string uses `String(localized:)`, and it is the accessibility label the phase explicitly protected.
- Fix: use a localized format key, e.g. `String(localized: "dashboard.arc.accessibility \(pctInt)")`.
- Positive: Add Drink uses localized keys (`action.cancel`, `addDrink.title`).

### 2. Visuals — 3/4 (WARNING)

- The arc is a single labelled accessibility element (good).
- It has no `accessibilityValue`, and risk state is conveyed by color alone. The label has no risk wording, and over-limit percentages are clamped, so an overage is not spoken through the arc label. (The combined Dashboard card announcement was owner-verified in UAT; this concerns the arc component's own label.)
- Fix: include the unclamped value or a risk word in the label/value.

### 3. Color — 3/4 (WARNING)

- `drinkpulse/DesignSystem/DPColors.swift:5-9` — five hardcoded `Color(red:green:blue:)` constants. They are centralized but have no dark-mode or increased-contrast variants.
- Fix: move them to asset-catalog colors with appearance variants.
- Positive: `dpRisk*` tokens are used consistently by the arc.

### 4. Typography — 2/4 (WARNING)

- `drinkpulse/DesignSystem/DPLargeTitle.swift:12` — `.font(.system(size: 28, weight: .bold))`.
- `drinkpulse/Features/AddDrink/Components/DrinkTypeTile.swift:10` — `.font(.system(size: 34))`.
- Both are fixed sizes that do not scale with Dynamic Type, which conflicts with the AX5 requirement. AX5 owner verification covered the retained History/Insights surfaces, not these.
- Fix: use a text style (`.largeTitle`, etc.) or `@ScaledMetric`.

### 5. Spacing — 3/4

- The arc defaults (size 100, stroke 9) are plain literals. No arbitrary-spacing abuse was found in the files audited; not every feature was scanned.

### 6. Experience Design — 4/4

- `AddDrinkView` reads `@Environment(\.dismiss)` once at the sheet root and passes `DismissAction` explicitly to the grid and detail views; Cancel and save are wired through it.
- The arc animation is gated by `hasSettledOnce`, so there is no first-paint animation.
- Strong evidence: DashboardUITests 5/5, AddDrinkFlowUITests 6/6, ShellNavigationUITests 4/4, 49/49 focused iOS 27 UI tests, plus the VoiceOver regression and owner checks.
- Accepted gap: under Reduce Motion, the native Add Drink sheet animation is treated as system behavior.
- Open observation: a ~1 s Dashboard flash after opening and closing Add Drink from Settings (`09-ADD-DRINK-EVIDENCE.md:39`) is recorded as under separate reproduction. Confirm it is resolved or tracked before release.

## Top Fixes

1. Localize the `DPArcProgress` accessibility label.
2. Replace the fixed `.system(size:)` fonts in `DPLargeTitle` and `DrinkTypeTile` with scalable text styles (AX5).
3. Add risk state and overage to the arc's spoken value, and add dark/high-contrast variants for the `DPColors` constants.

## Files Audited

- `drinkpulse/DesignSystem/DPArcProgress.swift`
- `drinkpulse/DesignSystem/DPColors.swift`
- `drinkpulse/DesignSystem/DPLargeTitle.swift`
- `drinkpulse/Features/AddDrink/AddDrinkView.swift`
- `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift`
- `drinkpulse/Features/AddDrink/Components/DrinkTypeTile.swift`

*Audit run by gsd-ui-auditor (findings spot-checked by the orchestrator); file written by the /gsd-ui-review orchestrator.*
