---
created: 2026-07-27T00:00:00.000Z
title: Replace generated launch screen with branded static launch screen
area: ui
severity: minor
cluster: B
resolves_phase: 4
files:
  - drinkpulse.xcodeproj/project.pbxproj:418,453 (INFOPLIST_KEY_UILaunchScreen_Generation = YES — blank generated launch screen)
  - drinkpulse/AppIcon.icon (existing icon asset — candidate source for launch branding)
---

## Problem

On a slow cold launch (after install, or after force-quit) the user stares at
a blank white screen.

`project.pbxproj:418,453` sets `INFOPLIST_KEY_UILaunchScreen_Generation = YES`,
i.e. Xcode auto-generates an empty launch screen — plain background, no icon,
no name, no indicator.

This is the **presentation** half of the original combined launch todo. The
reason the blank window is held for a noticeable duration is a separate,
structural problem tracked in
`2026-07-27-async-model-container-startup-and-error-state.md` (cluster A).
The two fixes are independent: a branded launch screen improves what the user
sees during the wait; it does not shorten the wait.

## Solution

TBD — deliberately the low-risk half:

- Replace the generated launch screen with one showing the app icon /
  wordmark, so the pre-first-frame window is branded rather than blank.
- **A real `UILaunchScreen` is static UIKit-side configuration, not SwiftUI.**
  It cannot show a spinner or animate — it is a still image by design. Set
  expectations accordingly; anything animated belongs to the in-app loading
  view, which is gated on the async-container work in cluster A.
- Keep it consistent with the existing `AppIcon.icon` asset rather than
  introducing new artwork.

Gate: user-facing, but there is no in-app screen to drive — verify on a **real
force-quit cold launch on device**, not a simulator warm start, since that is
the case the user actually reported. A `drinkpulseUITests` assertion on the
launch screen itself is not meaningful (it is pre-process UI); pin the
post-launch first screen instead if a test is added.

Size: small — a `/gsd-quick`.

Split from `2026-07-26-branded-launch-state-and-no-zero-animation-on-first-render.md`
on 2026-07-27; that todo bundled three items of three different sizes.

## Resolution (2026-07-31)

Resolved by Phase 4 (`04-branded-static-launch-screen`, plan 04-01). Shipped
as a `LaunchBackground.colorset` (dual-appearance, matches
`Color(.systemBackground)`) via a standalone `Info.plist`
(`GENERATE_INFOPLIST_FILE=NO`) wiring `UILaunchScreen` — background color
only. No app-icon image on the launch screen itself: iOS 26's SpringBoard
already animates the real Icon Composer `AppIcon` over the launch screen, so
a second copy was the actual defect (see Deviation 14 in
`.planning/milestones/v1.3-phases/04-branded-static-launch-screen/04-01-SUMMARY.md`).
Covered by `LaunchHandoffUITests` (onboarded + fresh-onboarding cold-launch
paths).
