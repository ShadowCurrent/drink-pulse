---
phase: 09-swiftui-design-system-modernization
reviewed: 2026-11-12T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - drinkpulse/DesignSystem/DPArcProgress.swift
  - drinkpulse/Domain/GuidelineLimits.swift
  - drinkpulse/Features/AddDrink/AddDrinkView.swift
  - drinkpulse/Features/AddDrink/DrinkDetailInputView.swift
  - drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift
  - drinkpulse/Features/AddDrink/DrinkTypeGridView.swift
  - drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift
  - drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: issues_found
---

# Phase 9: Code Review Report

**Reviewed:** 2026-11-12
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

The phase diff in scope is small. `\.dismissSheet` environment closure replaced by an explicit `DismissAction` passed from `AddDrinkView` through `DrinkTypeGridView` into `DrinkDetailInputView`. `nonisolated` annotations added to `ArcShape` and `GuidelineLimits.effectiveDailyGrams`. Two UI tests added.

The DismissAction plumbing is correct: `AddDrinkView` sits outside the `NavigationStack`, so its `dismiss` closes the sheet. No remaining reference to the removed `\.dismissSheet` key exists in the repo. `GuidelineLimits` change is sound; `effectiveDailyGrams` callers are guarded by `fraction()` (`limitGrams > 0`), so no divide-by-zero reaches `DPArcProgress`.

No blockers. Real defects live mostly in code that was touched or re-reviewed but not fixed: a dead arc animation, an unlocalized accessibility string, a custom-drink volume mismatch in US/imperial mode, and unvalidated price parsing. One new test overclaims what it verifies.

## Warnings

### WR-01: DPArcProgress animation never interpolates (ArcShape has no `animatableData`)

**File:** `drinkpulse/DesignSystem/DPArcProgress.swift:16-18, 33-51`
**Issue:** `.animation(hasSettledOnce ? .easeOut(duration: 0.4) : nil, value: pct)` drives a `Shape` whose `from`/`to` are plain `let` stored properties. `ArcShape` does not implement `animatableData`, so SwiftUI cannot interpolate `to`. The arc snaps to the new value. The `hasSettledOnce` state plus `onChange` machinery is therefore dead behavior: it suggests an animated arc that does not exist.
**Fix:**
```swift
nonisolated private struct ArcShape: Shape {
    var from: Double
    var to: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { .init(from, to) }
        set { from = newValue.first; to = newValue.second }
    }
    ...
}
```
Alternative: drop the animation and `hasSettledOnce` if a static arc is intended. Per AGENTS.md, verify `Shape`/`Animatable` behavior against Apple docs via Xcode MCP before changing.

### WR-02: DPArcProgress accessibility label hardcoded English; reduce-motion not honored

**File:** `drinkpulse/DesignSystem/DPArcProgress.swift:18, 27-30`
**Issue:** `"\(pctInt)% of daily limit"` bypasses `String(localized:)`, violating the project convention that all user-facing strings go through it. Also, the 0.4 s `.easeOut` animation does not check `@Environment(\.accessibilityReduceMotion)`, violating the accessibility rule "Honor reduceMotion for animations" (AGENTS.md). Percent is also exposed as label text rather than `accessibilityValue`, so VoiceOver reads the changing number as the element's name.
**Fix:**
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
...
.animation(hasSettledOnce && !reduceMotion ? .easeOut(duration: 0.4) : nil, value: pct)
.accessibilityLabel(String(localized: "dashboard.arc.label"))      // "Daily limit"
.accessibilityValue(String(localized: "dashboard.arc.value \(pctInt)"))
```
Add the keys to `Localizable.xcstrings`.

### WR-03: Custom drink in US/imperial mode saves a volume that is not in the picker options

**File:** `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift:34-40, 112`
**Issue:** For `.custom`, `volumeOptions` comes from `customVolumes(for:)`: in `.usCustomary`/`.imperial` those are 0.5 fl oz steps (about 14.79 ml multiples). `onAppear` sets `volumeMl = preset.defaultVolumeMl(for: unitSystem)`, which resolves against `preset.volumes(for:)`, a flat 10 ml..1000 ml list that contains 250. So `volumeMl = 250`, which is absent from the picker's tags (8.45 oz). The wheel has a selection that matches no row, shows an arbitrary row, and `save()` persists 250 ml while the user sees something else. `resolveVolumeForUnit()` (which would snap to the nearest valid option) is only called on `unitSystem` change, not on appear.
**Fix:** Resolve against the actual displayed options on appear:
```swift
.onAppear {
    syncAbvValues()
    volumeMl = preset.defaultVolumeMl(for: unitSystem)
    resolveVolumeForUnit()   // snap to volumeOptions
    ...
}
```
Add a UI or unit test for custom + imperial profile.

### WR-04: `parsedPrice` accepts NaN, infinity, negatives; silently drops grouped input

**File:** `drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift:49-52, 67-68`
**Issue:** `Double(normalized)` parses `"nan"`, `"inf"`, `"-5"` and `"1e999"`. `.decimalPad` blocks typing these, but pasting bypasses the keyboard. A NaN/inf/negative price is stored into `ConsumptionEvent.price` and flows into spend aggregates. Conversely `"1,234.50"` becomes `"1.234.50"`, parses to nil, and the price is silently discarded with no feedback. The comma-to-dot replace is a naive locale workaround; use a locale-aware parse.
**Fix:**
```swift
var parsedPrice: Double? {
    let trimmed = priceText.trimmingCharacters(in: .whitespaces)
    guard let v = try? Double(trimmed, format: .number), v.isFinite, v >= 0 else { return nil }
    return v
}
```
Add unit tests for `nan`, `inf`, `-1`, `1,5`, `1.234,50`.

### WR-05: VoiceOver UI test does not verify dismissal under VoiceOver and has no availability guard

**File:** `drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift:101-137`
**Issue:** Test name and section comment claim "VoiceOver dismissal semantics". The test disables VoiceOver at line 132 before `cancel.tap()`, so the dismissal it asserts is a plain tap, already covered by `test_dismissingAddDrink_returnsToPriorTab`. What it actually proves is that VoiceOver speaks "Cancel" within 40 swipes. This gives false assurance for the DismissAction refactor. Also, `voiceOverService` use has no `XCTSkip` guard when the service is unavailable, and the 40-swipe traversal is order- and timing-dependent (flaky). A stale `cancel` element reference is reused after toggling VoiceOver.
**Fix:** Rename to match behavior (`test_voiceOver_announcesCancelOnAddDrinkSheet`), or perform the activation through VoiceOver (`voiceOver.performAction(.activate)` or equivalent) while enabled, then assert dismissal. Skip when `XCUIDevice.shared.voiceOverService` throws on `enable()`. Re-query the Cancel button after toggling.

## Info

### IN-01: Preview of DrinkDetailInputView no longer previews the detail screen

**File:** `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift:128-134`, `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift:23-25`
**Issue:** Because `DismissAction` cannot be constructed outside the environment, both previews were replaced by `AddDrinkView()`, which shows the grid. The detail view preview lost its mock data (previous preview seeded an event) and cannot be opened directly; `DrinkTypeGridView` and `DrinkDetailInputView` previews are now identical to each other and to `AddDrinkView`. AGENTS.md requires previews with mock data per view.
**Fix:** Make the dismiss closure injectable (`let dismiss: () -> Void` wrapping `DismissAction` at the `AddDrinkView` boundary) so previews can pass `{}`; or wrap the preview in a host view that reads `\.dismiss` and navigates straight to `.beer`.

### IN-02: Save has no re-entry guard

**File:** `drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift:54-74`
**Issue:** `save()` inserts an event and then calls the asynchronous `dismissSheet()`. A fast double tap on Save before the sheet finishes dismissing runs `save()` twice and inserts two events (different UUIDs, so `ensureUniqueIdentity` will not catch it).
**Fix:** Add `@State private var didSave = false`; `guard !didSave else { return }; didSave = true` at the top of `save()`.

### IN-03: ArcShape radius ignores stroke width

**File:** `drinkpulse/DesignSystem/DPArcProgress.swift:44`
**Issue:** `radius = min(w, h) / 2 - 1` puts the stroke's outer edge at `size/2 - 1 + strokeWidth/2`, i.e. 3.5 pt beyond the 100 pt frame at the default stroke of 9. Round caps extend further. Rendering overflows its layout bounds and can clip against a parent clip shape or neighbor.
**Fix:** Pass stroke width into the shape or inset the rect: `.inset(by: strokeWidth / 2)` before computing radius.

### IN-04: Weak UI test locators

**File:** `drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift:71, 81`
**Issue:** `pickerWheels.element(boundBy: 2)` assumes the Amount wheel is third; reordering the pickers silently targets the wrong wheel. `eventButton(containing: "×2")` matches any History row label containing "×2", including seeded fixtures, so it can pass without the new log. Not confirmed that fixtures contain such a row.
**Fix:** Give the pickers accessibility identifiers (`addDrink.amountPicker`) and select by identifier; log a uniquely named event with quantity 2 and assert on `"<unique name> ×2"`.

---

_Reviewed: 2026-11-12_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
