---
created: 2026-07-27T00:00:00.000Z
title: Move model container creation off the synchronous init path and add a real error state
area: general
severity: minor
cluster: A
files:
  - drinkpulse/drinkpulseApp.swift:47-70 (sharedModelContainer built eagerly/synchronously, blocks first frame)
  - drinkpulse/drinkpulseApp.swift:59,68 (fatalError on container failure — hard crash, no user-facing error)
---

## Problem

`drinkpulseApp.swift:47` builds `sharedModelContainer` in an
**eagerly-evaluated stored-property closure** that runs synchronously during
`App` initialization. That closure calls `StoreBootstrap.makeContainer(...)`,
which on a first run (or post-install migration, or store recovery) does real
work before the first frame can be drawn. The launch window is held for
exactly as long as SwiftData needs.

Two consequences:

1. **No in-app loading state is possible.** Anything shown while the store
   opens (branded loading view, progress, pulse) requires the container to
   stop blocking the init path. The static launch screen
   (`2026-07-27-branded-static-launch-screen.md`, cluster B) covers the
   pre-process window; it cannot cover this one.
2. **Container failure hard-crashes.** `drinkpulseApp.swift:59` and `:68`
   call `fatalError`. Making startup async does not remove those paths — it
   forces the question of what the user should actually see when the store
   cannot be opened. Per CLAUDE.md, errors are typed and either handled
   meaningfully or surfaced to the user; a `fatalError` on a migration or
   store-recovery failure is neither.

## Solution

TBD — this is a **structural change to app startup**, not a tweak:

- Move container creation off the synchronous `App` init so the first frame
  can be drawn before the store is ready.
- Replace the two `fatalError` call sites with a real user-facing error state.
  This needs a design decision before coding: what does the app show when the
  store cannot open, and what recovery (retry / reset / contact) is offered.
  A store-open failure can mean user data is at risk — do not design a path
  that silently discards it.
- Only once the container is off the init path can an in-app loading view
  (icon + subtle pulse) be added. If one is used, CLAUDE.md accessibility
  rules apply: meaningful `accessibilityLabel`, honor `reduceMotion` (follow
  `Features/Onboarding/OnboardingView.swift:80`).

## Why cluster A (Swift 6), not cluster B

Making container creation async **is a concurrency change**. Doing it while
the app target is still on `SWIFT_VERSION = 5.0` means reasoning about
isolation and `Sendable` boundaries once under the permissive Swift 5 rules,
then again when the target flips to Swift 6 mode
(`2026-07-26-migrate-app-target-to-swift-6-language-mode.md`). Sequencing it
inside the same milestone — ideally **after** the language-mode flip — means
the isolation work is done once, under the rules that will actually be
enforced.

Size: plan-worthy (`docs/plans/NNNN-*/`) — multi-file, touches app startup and
adds a new error-handling surface.

Split from `2026-07-26-branded-launch-state-and-no-zero-animation-on-first-render.md`
on 2026-07-27; that todo bundled three items of three different sizes.
