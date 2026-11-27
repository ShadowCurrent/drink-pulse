# 0048 — Retrospective

**Completed**: 2026-11-25 (one session, inline, superpowers `executing-plans`).

## What shipped
- About You: sex is required (Continue disabled until chosen, no silent "Male"); segmented control
  with no selection at regular sizes, choice rows at accessibility sizes; date of birth behind
  "Add Date of Birth".
- Only reachable pages are in the paged `TabView`, so a swipe cannot skip About You.
- Completion runs once (`isCompleted`); a failed save is logged by error type only.
- Chrome: glass circle Back always laid out (one header height), rounded headings, Frost backdrop,
  `BrandSurface` cards (no `.thinMaterial`), `.glassProminent` primary, `dpDeniedText`, VOICE copy.
- First run: `drinkpulseApp` always shows the shell; onboarding is a full-screen cover owned by
  the shell. Pending notification actions wait for the cover. After Done: Today's cards rise in,
  the arc track draws, one success haptic.

## What went well
- The view-model rules (required sex, reachable pages, one completion) went in test-first and
  carried the UI work.
- One-control-at-a-time swaps localized every audit finding in a few short runs, which made the
  owner's D0048-18 decision a concrete one.

## What went badly
- The plan had Task 4 implement before its tests, and in Task 5 the implementation was drafted
  before the RED run (moved out and back). Both are recorded.
- `accessibilityHidden(true)` did not hide the disabled glass Back button; one wasted run before
  switching to `hidden()`.
- Background `RunSomeTests` runs (≥ 2 min) idle the session; batching edits around them helped.

## Surprises (iOS 27.2)
- A disabled `.glass` button stays in the accessibility tree under `opacity(0)` +
  `accessibilityHidden(true)`; `hidden()` removes it.
- `.glassProminent`, a disabled primary and an unselected segmented control each give
  element-less `contrast` audit issues; the same audit passes with `.borderedProminent`.
- `brandBackground()` (`containerBackground(for: .navigation)`) has nothing to fill outside a
  NavigationStack.

## Follow-ups
- Owner device checks (open-questions "Plan 0048 follow-ups"): D0048-2 launch with no slide-up
  or flash, D0048-18 with Accessibility Inspector, swipe over the segmented control, entrance and
  haptic, Reduce Motion, VoiceOver, Increase Contrast.
- "History edit UI tests fail on their own" stays open (no full suite at step 8, D0048-15).
- Step 9: copy pass, including the "Weekly Summary" rename.
