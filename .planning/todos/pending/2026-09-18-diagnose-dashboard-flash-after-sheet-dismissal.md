---
created: 2026-09-18T19:19:46.809Z
title: Diagnose Dashboard flash after sheet dismissal
area: general
severity: major
files:
  - drinkpulse/Features/Shell/RootShellView.swift
  - drinkpulse/Features/Dashboard/DashboardView.swift
  - drinkpulse/DesignSystem/DPGlass.swift
---

## Problem

On an iPhone 15 Pro Max running iOS 27, Dashboard visibly flashes after every
cycle of opening Add Drink, dismissing it, and switching to another tab. The
same navigation flow completes correctly on the iOS 27 simulator, but Xcode
MCP's first static screenshot is available only after the approximately
one-second artifact has elapsed, so it cannot prove the rendering cause.

The issue persists after Dashboard cards were placed in
`GlassEffectContainer(spacing: 0)`. The user explicitly deferred further work
on this problem to keep the iOS 27 modernization milestone focused.

## Solution

Diagnose this as a dedicated real-device rendering/presentation issue before
making another source change. Capture the transition on the affected device,
then correlate it with sheet dismissal, `TabView` selection, Dashboard view
invalidations, and Liquid Glass composition. Consult Apple documentation and
Xcode MCP first; retain the current navigation and accessibility behavior until
a reproducible cause supports a narrow fix.

## Status 2026-11-13: deferred from Phase 09

The owner deferred this problem out of Phase 09 ("Backlog / todo"; owner statement in
`.planning/phases/09-swiftui-design-system-modernization/09-FLASH-DIAGNOSIS.md`, section
"Owner deferral of D1 (2026-11-13)"). This todo has no `resolves_phase` frontmatter, so
closing Phase 09 does not auto-close it. It stays open. Nothing is fixed: the Dashboard
`GlassEffectContainer` from commit `553ea58` was reverted (plan 09-08), and that revert
fixes neither symptom below.

### Two symptoms, possibly distinct defects

1. Device and simulator flicker. The whole screen blinks for about 1 second after Add
   Drink is dismissed and a tab is switched (owner: "wszystko dosłownie mryga"). Seen on
   the simulator during the harness run and on the iPhone 15 Pro Max, in light and in dark
   (weaker in dark). The owner says it has existed since iOS 26. Not measured; not proven
   to share a cause with symptom 2.
2. iOS 27 simulator crash. Intermittent `EXC_BREAKPOINT` in private `DesignLibrary`
   (`MaterialProviderBox.resolveLayers(in:)`, `GlassEffectResolvedMaterial.value.getter`)
   on the first update after a tab switch onto a tab with a live `glassEffect` card, after
   an Add Drink then Cancel sheet cycle. One live glass card on either tab is enough.
   Reproduced in the standalone minimal repro (1 of 2 completed glass runs; the
   `.regularMaterial` control was clean 2 of 2). Our `DesignLibrary` frames are
   unsymbolicated (names not recoverable from the stripped shared cache; disassembly is
   structurally consistent with a range trap, not name-confirmed).

### Findings and where they live

- `09-FLASH-DIAGNOSIS.md`, all in `.planning/phases/09-swiftui-design-system-modernization/`:
  "Crash isolation" and "Crash isolation round 2" (variants and results), "Minimal repro"
  and "Draft Feedback text (not submitted)", "Hypotheses and predictions (H1 to H5)",
  "Conclusion (plan 09-07)", "New flicker hypothesis H6", "Owner live observation",
  "Video-based flicker measurement" (pre-registered, unused), and
  "Owner deferral of D1 (2026-11-13)" (the full open-items list).
- Branches (local, never pushed or merged): `diag/09-flash-v1-no-container`,
  `diag/09-flash-v3-trivial-sheet`, `diag/09-flash-v4-material`, `diag/09-crash-r2-dash`,
  `diag/09-crash-r2-dash-A`, `diag/09-crash-r2-dash-A1`, `diag/09-crash-r2-ins`,
  `diag/09-crash-r2-ins-A`, `diag/09-crash-r2-ins-A1`.
- Work areas outside the repository: `/Users/fempter/Developer/drinkpulse-diag/work` (stable
  diag worktree, detached at the harness commit) and
  `/Users/fempter/Developer/drinkpulse-diag/minimal-repro` (standalone project, no app
  data, UI test `MR1` plus candidate tests G1, G2, G3, G5, G6).
- External leads (third-party, not independently verified): `salehtl/hasala` PR 167
  (`https://github.com/salehtl/hasala/pull/167`, range-trap family; workaround moved
  `glassEffect` from inside a `Button` label onto the `Button`) for the crash;
  `software-mansion/react-native-screens` issue 4163 (glass re-created on tab refocus
  paints one frame with the wrong appearance) for hypothesis H6.
- Skipped harness tests: in `drinkpulse.xcodeproj/xcshareddata/xcschemes/drinkpulse.xcscheme`
  (`SkippedTests` under the `drinkpulseUITests` testable),
  `SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_cycle_staysNavigable_recordsFrameDeltas()`
  and `SheetDismissTabSwitchUITests/test_sheetCancelThenTabSwitch_emptyStore_recordsFrameDeltas()`.
  The code is kept; the no-sheet control `test_tabSwitchWithoutSheet_control_recordsFrameDeltas()`
  stays enabled. Note: an explicit class selection through Xcode MCP `RunSomeTests` runs the
  skipped methods anyway (they crash), so use explicit method identifiers when resuming.
  Remove the scheme entries when D1 is resumed or fixed.

### Not done at deferral

H1 to H5 and H6 untested; crash candidates G1, G2, G3, G5, G6 never measured (the round was
stopped before any candidate ran); the video flicker metric is pre-registered but no video
exists; the Apple Feedback draft is not submitted; no owner-device session for the minimal
repro or for the `dp_color_scheme` check (H6).

### Resume recipe

1. Use the stable path `/Users/fempter/Developer/drinkpulse-diag/work` for app-level
   diagnostics and the `minimal-repro` project for crash work; drive both through Xcode MCP
   per the owner rule (open each path with `XcodeOpenWorkspace` once, pass its own
   `workspaceIdentifier`, never mix it with the main project). CLI only for a named missing
   capability (for example `xcrun simctl io <udid> recordVideo`).
2. Start with the crash-versus-flicker discriminator: a crash plus runner relaunch also
   looks like a whole-screen blink, so classify every blink (crash report in
   `~/Library/Logs/DiagnosticReports`, next phase line present, app still running) before it
   counts.
3. Run the video flicker metric exactly as pre-registered ("Video-based flicker
   measurement"): no-sheet control at least twice for the noise floor, then HEAD, then the
   material control.
4. Run the owner-device checks that need no code: the H6 appearance comparison (system vs
   explicit override, 6 cycles per tab) and the minimal repro on the iPhone.
5. Only then revisit the crash candidates under the pre-registered acceptance rule, and
   submit the Feedback draft once the repro is stable.
