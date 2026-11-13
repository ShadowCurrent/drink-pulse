---
phase: 09-swiftui-design-system-modernization
reviewed: 2026-11-13T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - drinkpulse/Domain/GuidelineLimits.swift
  - drinkpulse/Features/Dashboard/DashboardView.swift
  - drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift
  - drinkpulseUITests/Features/Shell/SheetDismissTabSwitchUITests.swift
  - drinkpulse.xcodeproj/xcshareddata/xcschemes/drinkpulse.xcscheme
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 9: Code Review Report (gap-closure re-review)

**Reviewed:** 2026-11-13
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Re-review of the Phase 09 gap-closure changes since the 2026-11-12 review (`git diff 2752748..HEAD`): plan 09-04 (`GuidelineLimits`), 09-05 (VoiceOver test rewrite), 09-06 (flash harness), 09-08 (Dashboard revert and scheme skips).

Production code is clean:

- `GuidelineLimits.swift`: `effectiveDailyGrams` moved into the `nonisolated` struct body, so it now inherits `nonisolated` explicitly. Behavior unchanged. Callers (`DashboardViewModel`, `InsightsViewModel`, `HistoryCalendarView`) go through `effectiveLimits(...)` or guard `> 0`; `.custom` via `limits(for:)` yields 0 but the Insights path guards it. Unit tests cover the property (`GuidelineLimitsTests`).
- `DashboardView.swift`: `git diff 553ea58~1 HEAD` on this file is empty, so the revert is byte-exact to the pre-`GlassEffectContainer` form. No new defects. Note: this revert does not address the iOS 27 simulator crash (the diagnosis V1 variant crashed without the container); see WR-06.

Prior WR-05 (VoiceOver test) is resolved in substance: VoiceOver now stays enabled through the Cancel activation, Cancel is re-queried after toggling, and `failedToStart` maps to `XCTSkip`. `XCUIVoiceOverService.isEnabled`, `enable()`, `disable()`, `currentSpeech()`, `moveForward()`, `Output.utterance`, and `Error.failedToStart` were confirmed against Apple documentation (XCUIAutomation) via Xcode MCP `DocumentationSearch`. Remaining defects are test-robustness and a masked crash. No blockers in source.

New finding IDs continue numbering (WR-06 onward) so the dispositions in `09-REVIEW-DISPOSITION.md` for WR-01..WR-05 and IN-01..IN-04 stay valid.

## Warnings

### WR-06: Deterministic iOS 27 simulator crash in the Add Drink -> Cancel -> tab-switch flow is masked by a scheme-level skip

**File:** `drinkpulse.xcodeproj/xcshareddata/xcschemes/drinkpulse.xcscheme:66-73`, `drinkpulseUITests/Features/Shell/SheetDismissTabSwitchUITests.swift:40-48, 56-65`
**Issue:** `09-FLASH-DIAGNOSIS.md` records the sheet cycle crashing the app (`EXC_BREAKPOINT` in private `DesignLibrary` / `MaterialProviderBox.resolveLayers`) in 4 of 4 HEAD runs, and a standalone minimal repro crashed 1 of 2 glass runs. That is an ordinary user flow. The only reproducers of this crash in the repo are the two tests now listed under `SkippedTests`, so the default `xcodebuild test` and Xcode MCP `RunAllTests` gates no longer exercise it. The skip is documented (test comments, todo, diagnosis), the owner deferred D1, and the crash has not been observed on a device, so this is classed WARNING, not BLOCKER. But the shipped app contains the pattern that traps in private SwiftUI glass code, the 09-08 revert did not change that, and nothing in the automated gate will notice if the crash starts reproducing on real hardware or if the skip is forgotten (the skip lives only in the scheme; `shouldAutocreateTestPlan = "YES"` and any other scheme or test plan will run or drop it silently).
**Fix:** Keep the deferral, but make it loud and non-silent: (1) add a tracked item in `ROADMAP.md`/`open-questions.md` that the Phase 09 close ships with a known simulator crash and an unconfirmed device status; (2) add `try XCTSkip("D1: iOS 27 simulator Liquid Glass crash, see <todo path>")` guarded by an env flag (for example run only when `DP_RUN_D1_HARNESS` is set) so the reason prints in test logs instead of the test vanishing from the report; (3) re-verify on the iPhone 15 Pro Max or a newer iOS 27 seed before any release build.

### WR-07: VoiceOver teardown swallows `disable()` failure; a leaked VoiceOver session would silently corrupt every later UI test

**File:** `drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift:120`
**Issue:** `addTeardownBlock { try? voiceOver.disable() }` discards the error with no comment (project rule: no `try?` unless the failure is genuinely ignorable and a comment says why). If `disable()` throws (`failedToStop`), VoiceOver stays on for the rest of the run. Every other UI test class (`launchApp()` in each) assumes VoiceOver is off and does not guard; they would fail or behave differently (taps interpreted as VoiceOver gestures) with a misleading cause far from this test. The pre-check at lines 102-104 only protects this one test.
**Fix:**
```swift
addTeardownBlock {
    do { try voiceOver.disable() }
    catch { XCTFail("VoiceOver could not be disabled; later UI tests are unreliable: \(error)") }
}
```
Optionally centralize a `disableVoiceOverIfNeeded()` helper used by the shared `launchApp` helpers.

## Info

### IN-05: VoiceOver error handling is partial and the skip message prints a constant

**File:** `drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift:121-131`
**Issue:** (a) `catch XCUIVoiceOverService.Error.failedToStart { throw XCTSkip("... \(XCUIVoiceOverService.Error.failedToStart)") }` interpolates the static error code, not the caught error, so the skip reason is always the same string and carries no underlying detail. (b) Only `failedToStart` becomes a skip; `currentSpeech()` on line 127 and `moveForward()` on line 130 are plain `try`, and the documented error codes include `noSpeech` and `notRunning`. If `currentSpeech()` is called before VoiceOver has spoken, the test would fail as an infrastructure error rather than retry or skip. Not proven to occur, but the code does not rule it out.
**Fix:** `catch let error as XCUIVoiceOverService.Error where error.code == .failedToStart { throw XCTSkip("VoiceOver could not start: \(error)") }`, and treat a `noSpeech` from the first `currentSpeech()` as "no utterance yet" (start the list empty) before the traversal loop.

### IN-06: Non-asserting flash harness control test runs in the default UI suite

**File:** `drinkpulseUITests/Features/Shell/SheetDismissTabSwitchUITests.swift:50-54`
**Issue:** `test_tabSwitchWithoutSheet_control_recordsFrameDeltas` is not skipped. It does 20 landings, each sleeping until 3.0 s after the tap and taking 9 full-screen screenshots, plus 20 `keepAlways` string attachments, so it adds roughly 1 to 2 minutes to every UI run and asserts only that tabs stay navigable, which `ShellNavigationUITests` already covers. The metric is never asserted, so it gives no regression signal. It also leaves `DP_FLASH_METRIC` `print` output in normal logs. (Debug-only test code, so the project `print` rule is relaxed, but this is noise.)
**Fix:** Gate the harness behind an opt-in (for example `try XCTSkipUnless(ProcessInfo.processInfo.environment["DP_FLASH_METRICS_PATH"] != nil)` in `setUpWithError`), so it runs only when someone is measuring. That also gives the crashing tests a loud skip reason (see WR-06).

### IN-07: Harness can report a false "no flash" and its time origin is optimistic

**File:** `drinkpulseUITests/Features/Shell/SheetDismissTabSwitchUITests.swift:121-130, 171-177`
**Issue:** (a) In `grayGrid`, if `CGContext(...)` returns nil the closure `return`s silently, leaving a zero-filled grid with no failure. The reference and every sample are then identical zero grids, and `record` emits `maxDelta=0.00000`, which reads as "no flash". Practically unreachable for these parameters, but the failure mode is a silent false negative in an evidence instrument. (b) `tapTime = Date()` is taken after `button.tap()` returns; XCUITest synthesis includes idle waiting, so the 0.6 s first sample is measured from a point already after part of the transition, and the `waitForExistence` on the nav bar is not included. A ~1 s flash may be partially missed. Unverified, but the offsets were pre-registered against the tap time.
**Fix:** `XCTFail("CGContext creation failed")` in the `else` branch of the `CGContext` guard (or throw). Capture `Date()` immediately before `button.tap()` and document the bias, or accept and note it in the harness header.

### IN-08: `append(_:toFileAt:)` does not close the file handle on write failure

**File:** `drinkpulseUITests/Features/Shell/SheetDismissTabSwitchUITests.swift:210-223`
**Issue:** `handle.close()` sits after `seekToEnd()`/`write`; if either throws, the handle leaks until deinit. Minor; test-only.
**Fix:** `defer { try? handle.close() }` right after creating the handle (with a comment that close failure is ignorable), or use `do { try handle.seekToEnd(); try handle.write(contentsOf: data) }` followed by an unconditional close.

---

_Reviewed: 2026-11-13_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

---

## Prior review (2026-11-12)

Preserved verbatim from the previous `09-REVIEW.md` (frontmatter at that time: `reviewed: 2026-11-12T00:00:00Z`, `depth: standard`, `files_reviewed: 8`, `critical: 0`, `warning: 5`, `info: 4`, `total: 9`, `status: issues_found`; files: `drinkpulse/DesignSystem/DPArcProgress.swift`, `drinkpulse/Domain/GuidelineLimits.swift`, `drinkpulse/Features/AddDrink/AddDrinkView.swift`, `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift`, `drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift`, `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift`, `drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift`, `drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift`). WR-05 was dispositioned `fixed` (plan 09-05) and is re-evaluated above; the other eight were dispositioned `deferred` in `09-REVIEW-DISPOSITION.md`.

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
