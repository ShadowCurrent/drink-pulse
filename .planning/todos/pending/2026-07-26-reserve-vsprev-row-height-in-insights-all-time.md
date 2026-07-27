---
created: 2026-07-26T17:50:00.000Z
title: Reserve vs-prev row height in Insights all-time hero card
area: ui
severity: cosmetic
cluster: B
files:
  - drinkpulse/Features/Insights/Components/InsightsHeroCard.swift:31-35 (if !vm.isAllTime { Text(vsPrevLabel) } — the collapsing row)
  - drinkpulse/Features/Insights/Components/InsightsHeroCard.swift:40-43 (TrendBadge, also hidden on all-time)
  - drinkpulse/Features/Insights/InsightsViewModel.swift:217 (isAllTime — "All-time has no previous period")
  - drinkpulse/Localizable.xcstrings:992 (insights.hero.vsPrev = "vs prev. %1$@ · %2$@")
---

## Problem

In Insights, the hero card shows a caption line under the consumed-units total
reading `vs prev. <period> · <value>` for the **Week**, **Month**, and **Year**
scopes. In the **All** scope that line is absent, so the card is shorter and
everything below it shifts up — a visible jump when switching periods.

Confirmed in `InsightsHeroCard.swift:31-35`:

```swift
if !vm.isAllTime {
    Text(vsPrevLabel)
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

The `Text` is conditionally *absent* from the `VStack`, not merely hidden, so
the stack loses that line's height plus its 4pt spacing. `TrendBadge` at
:40-43 is gated on the same condition, but it lives in the trailing `HStack`
and is top-aligned, so the height is driven by the left `VStack` — the caption
row is the cause.

Hiding it is intentional, not a bug: `InsightsViewModel.swift:217` notes
"All-time has no 'previous' period; the hero hides the comparison for it."
The ask is to keep the space reserved, not to show a comparison.

## Solution

TBD — reserve the line's height without rendering text:

- Replace the `if` with an always-present `Text` that is invisible in the
  all-time case (e.g. rendered with `.hidden()` / zero opacity), so the layout
  keeps the exact caption line-height. Prefer a real `Text` over a fixed-height
  spacer: a hardcoded height will **break under Dynamic Type** (CLAUDE.md
  requires layouts to hold up to AX5), whereas a hidden `Text` with the same
  `.font(.caption)` scales with the user's type size automatically.
- **Must not leak to VoiceOver.** A blank/invisible string still gets picked up
  by accessibility unless explicitly excluded — mark the placeholder
  `.accessibilityHidden(true)`. CLAUDE.md makes accessibility a hard
  requirement, and the card already declares
  `.accessibilityElement(children: .contain)` at :14, so an empty child would
  otherwise land in that container.
- Decide whether `TrendBadge` (:40-43) also needs space reserved. It probably
  does not affect height today, but confirm at large Dynamic Type sizes where
  the badge could become the taller element.
- Do not fabricate a comparison value for all-time — there is genuinely no
  previous period. The placeholder must stay empty, not show `0.0` or a dash
  that could read as real data.

Gate: user-facing change to an existing screen, so per CLAUDE.md at least one
`drinkpulseUITests` test is required and must actually run. Existing candidate
to extend: `drinkpulseUITests/Features/Insights/InsightsUITests.swift`. Note
that asserting "no layout shift" in XCUITest is awkward — a reasonable pin is
that a known element below the hero card holds a stable frame origin across a
Week→All switch, or simply that the all-time hero card's height matches the
other scopes'.

Size: small — a `/gsd-quick`.
