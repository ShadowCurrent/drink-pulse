---
created: 2026-07-26T17:30:00.000Z
title: Branded launch state and no zero-animation on first render
area: ui
severity: minor
files:
  - drinkpulse.xcodeproj/project.pbxproj:418,453 (INFOPLIST_KEY_UILaunchScreen_Generation = YES — blank generated launch screen)
  - drinkpulse/drinkpulseApp.swift:47-70 (sharedModelContainer built eagerly/synchronously, blocks first frame)
  - drinkpulse/DesignSystem/DPArcProgress.swift:17 (.animation(.easeOut(0.4), value: pct))
  - drinkpulse/Features/Dashboard/Components/ConsumptionOverviewCard.swift:111 (.animation(.easeOut(0.5), value: pctClamped))
  - drinkpulse/AppIcon.icon (existing icon asset — candidate source for launch branding)
---

## Problem

User reports two separate symptoms on app start. Both reproduce from the code,
and they have **different causes** — fixing one will not fix the other.

**1. White screen on a slow cold launch (after install, or after force-quit).**

`project.pbxproj:418,453` sets `INFOPLIST_KEY_UILaunchScreen_Generation = YES`,
i.e. Xcode auto-generates an empty launch screen — a plain background with no
icon, no name, no indicator. Whatever the launch takes, the user stares at
blank white.

The launch is not instant because `drinkpulseApp.swift:47` builds
`sharedModelContainer` in an **eagerly-evaluated stored-property closure**
that runs synchronously during `App` initialization. That closure calls
`StoreBootstrap.makeContainer(...)`, which on a first run (or post-install
migration, or store recovery) does real work before the first frame can be
drawn. So the blank window is held for exactly as long as SwiftData needs.

**2. Progress indicators animate up from zero on first render.**

`DPArcProgress.swift:17` and `ConsumptionOverviewCard.swift:111` both attach
`.animation(_:value:)` keyed on the percentage. On initial appearance the
value transitions `0 → actual`, so the arcs/bars visibly "spawn from zero"
every single launch. That easing is desirable when the number *changes* during
a session (e.g. after logging a drink) but wrong as an entrance — it reads as
the data loading in, even when the store was ready instantly.

## Solution

TBD — two independent fixes, do not conflate them:

**A. Give the launch a branded state.**
- Replace the generated launch screen with one showing the app icon /
  wordmark, so the pre-first-frame window is branded rather than blank.
  Note a real `UILaunchScreen` is **static UIKit-side configuration**, not
  SwiftUI, and cannot show a spinner or animate — it is a still image by
  design. Set expectations accordingly.
- For the *in-app* portion (container ready → data queried → first real
  content), a SwiftUI loading view with the icon and a subtle pulse is
  possible, but only if container creation moves off the synchronous
  init path. Making that async is a **structural change to app startup**
  and interacts with `fatalError` on container failure
  (`drinkpulseApp.swift:59,68`) — those hard-crash paths would need a real
  user-facing error state instead. Decide scope before coding: branded
  static launch screen alone is low-risk; async container + loading view is
  a much bigger change.
- If a spinner is used anywhere, the CLAUDE.md accessibility rules apply:
  meaningful `accessibilityLabel`, and honor `reduceMotion` (follow the
  existing pattern at `Features/Onboarding/OnboardingView.swift:80`).

**B. Suppress the entrance animation, keep the update animation.**
- Both call sites need the animation to apply only to *subsequent* value
  changes, not the initial `0 → value` render. Common approaches: seed the
  state with the real value before the first animated render, or gate the
  animation behind a "has appeared" flag.
- These are two shared/design-system components used beyond the Dashboard —
  check every consumer of `DPArcProgress` before changing its behaviour, and
  keep the two fixes consistent with each other.

**Gates** (CLAUDE.md): user-facing change to displayed values/screens, so a
`drinkpulseUITests` test is required and must actually run. Testing "no
entrance animation" in XCUITest is unreliable — assert the end state and
correctness, not timing. Verify the launch-screen change on a **real
force-quit cold launch**, not just a simulator warm start, since that is the
case the user actually reported.

Size: (A) branded static launch screen is small; (A) async container is
plan-worthy; (B) is small. Consider splitting — B alone is a good
`/gsd-quick`.
