---
created: 2026-07-27T00:00:00.000Z
title: Suppress entrance animation on first render of progress indicators
area: ui
severity: cosmetic
cluster: B
files:
  - drinkpulse/DesignSystem/DPArcProgress.swift:17 (.animation(.easeOut(0.4), value: pct))
  - drinkpulse/Features/Dashboard/Components/ConsumptionOverviewCard.swift:111 (.animation(.easeOut(0.5), value: pctClamped))
---

## Problem

`DPArcProgress.swift:17` and `ConsumptionOverviewCard.swift:111` both attach
`.animation(_:value:)` keyed on the percentage. On initial appearance the
value transitions `0 → actual`, so the arcs/bars visibly "spawn from zero"
every single launch.

That easing is desirable when the number *changes* during a session (e.g.
after logging a drink) but wrong as an entrance — it reads as the data loading
in, even when the store was ready instantly.

## Solution

TBD:

- Both call sites need the animation to apply only to *subsequent* value
  changes, not the initial `0 → value` render. Common approaches: seed the
  state with the real value before the first animated render, or gate the
  animation behind a "has appeared" flag.
- `DPArcProgress` is a **DesignSystem component used beyond the Dashboard** —
  check every consumer before changing its behaviour, and keep the two fixes
  consistent with each other.
- Keep the animation curve choice consistent with the rest of cluster B (the
  History row-diff and segment-transition todos) so the app does not end up
  with four different easings.

Gate: user-facing change to a displayed value, so per CLAUDE.md at least one
`drinkpulseUITests` test is required and must actually run. Asserting "no
entrance animation" in XCUITest is unreliable — assert the end state and
correctness, not timing.

Size: small — a `/gsd-quick`, and a natural fit alongside the other cluster-B
motion work.

Split from `2026-07-26-branded-launch-state-and-no-zero-animation-on-first-render.md`
on 2026-07-27; that todo bundled three items of three different sizes.
