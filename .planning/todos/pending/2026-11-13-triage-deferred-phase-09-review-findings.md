---
created: 2026-11-13T20:00:00.000Z
title: Triage deferred Phase 09 code-review findings (WR-01 to WR-04, IN-01 to IN-04)
area: general
severity: minor
files:
  - drinkpulse/DesignSystem/DPArcProgress.swift
  - drinkpulse/Features/AddDrink/DrinkDetailInputView.swift
  - drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift
  - drinkpulse/Features/AddDrink/DrinkTypeGridView.swift
  - drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift
audit_acknowledged:
  milestone: v1.4
  at: 2026-11-18
---

## Problem

Phase 09 code review (`.planning/phases/09-swiftui-design-system-modernization/09-REVIEW.md`) reported nine
findings. WR-05 was fixed by plan 09-05. The other eight were deferred by owner decision O3 (2026-11-13) so that
`09-REVIEW-DISPOSITION.md` shows zero open findings. Each deferral reason was checked against git history
(Phase 09 base commit `2752748`): all but IN-01 describe behavior that predates Phase 09. One section per finding
follows, each with the file and line reference from the review, the reason, and the suggested fix as a starting
point. Check any Apple API in a fix against Apple documentation through Xcode MCP first.

## WR-01: DPArcProgress animation never interpolates (ArcShape has no `animatableData`)

- Where: `drinkpulse/DesignSystem/DPArcProgress.swift:16-18, 33-51`
- Reason deferred: pre-existing; the animation modifier dates from 2026-07-28 and `ArcShape` never had
  `animatableData`. Phase 09 only added `nonisolated`.
- Suggested fix: give `ArcShape` `var from`, `var to` and
  `animatableData: AnimatablePair<Double, Double>`, or drop the animation and `hasSettledOnce` if a static arc is
  intended. Verify `Shape`/`Animatable` behavior in Apple docs first.

## WR-02: DPArcProgress accessibility label hardcoded English; reduce-motion not honored

- Where: `drinkpulse/DesignSystem/DPArcProgress.swift:18, 27-30`
- Reason deferred: pre-existing; the hardcoded label and the missing Reduce Motion check predate Phase 09.
- Suggested fix: read `@Environment(\.accessibilityReduceMotion)` and skip the animation when set; use
  `String(localized:)` for the label and expose the percentage through `accessibilityValue`; add keys to
  `Localizable.xcstrings`.

## WR-03: Custom drink in US/imperial mode saves a volume that is not in the picker options

- Where: `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift:34-40, 112`
- Reason deferred: pre-existing; `volumeOptions` and the `onAppear` default date from June 2026 and plan 09-02 did
  not touch them.
- Suggested fix: after `volumeMl = preset.defaultVolumeMl(for: unitSystem)` in `onAppear`, call
  `resolveVolumeForUnit()` so the value snaps to `volumeOptions`; add a test for a custom drink with an imperial
  profile. This changes what is saved, so write the test first.

## WR-04: `parsedPrice` accepts NaN, infinity, negatives; silently drops grouped input

- Where: `drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift:49-52, 67-68`
- Reason deferred: pre-existing; `parsedPrice` dates from 2026-06-27 and Phase 09 did not change it.
- Suggested fix: parse locale-aware (`try? Double(trimmed, format: .number)`) and require `isFinite` and `>= 0`;
  add tests for `nan`, `inf`, `-1`, `1,5`, `1.234,50`.

## IN-01: Preview of DrinkDetailInputView no longer previews the detail screen

- Where: `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift:128-134`,
  `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift:23-25`
- Reason deferred: informational; introduced by plan 09-02 (a `DismissAction` cannot be built outside the
  environment, so both previews were replaced by `AddDrinkView()`). Preview-only, no runtime effect.
- Suggested fix: wrap the preview in a host view that reads `\.dismiss` and pushes straight to `.beer`, or make
  the dismiss closure injectable. AGENTS.md requires previews with mock data per view.

## IN-02: Save has no re-entry guard

- Where: `drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift:54-74`
- Reason deferred: pre-existing; `save()` never had a guard, plan 09-02 only changed the dismiss call.
- Suggested fix: `@State private var didSave = false` and `guard !didSave else { return }; didSave = true` at the
  top of `save()`; add a UI test with a fast double tap.

## IN-03: ArcShape radius ignores stroke width

- Where: `drinkpulse/DesignSystem/DPArcProgress.swift:44`
- Reason deferred: pre-existing; the radius line dates from 2026-05-19 and is unchanged.
- Suggested fix: inset the rect by `strokeWidth / 2` before computing the radius, or pass the stroke width into the
  shape.

## IN-04: Weak UI test locators

- Where: `drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift:71, 81`
- Reason deferred: pre-existing; both locators date from 2026-06-24 and sit outside the lines plan 09-02 changed.
- Suggested fix: add accessibility identifiers to the pickers and select by identifier; log a uniquely named event
  with quantity 2 and assert on its row label.
