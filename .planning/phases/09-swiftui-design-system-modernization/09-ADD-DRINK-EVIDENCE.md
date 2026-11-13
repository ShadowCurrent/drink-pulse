# Add Drink evidence — Phase 09

**Date:** 2026-09-18  
**Toolchain:** Xcode 27.0 (27A266a), iPhoneSimulator SDK 27.0  
**Runtime:** iOS 27.0 — iPhone 18 Pro  
**LOCAL_IOS_27_UDID:** `1D35E1B8-4141-4EFF-A493-52CB37B600A5`

## Changed and checked paths

- `drinkpulse/Features/AddDrink/AddDrinkView.swift` reads the sheet-root `@Environment(\.dismiss)` action.
- `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift` passes the typed `DismissAction` through the existing navigation route and invokes it for grid cancellation.
- `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift` uses that same action for detail cancellation.
- `drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift` invokes it only after insertion, identity de-duplication, and Health write hooks.
- `drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift` covers originating-tab grid cancellation and save-plus-persistence.
- `drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift` covers semantic Cancel discovery and the Xcode 27 `voiceOverService` dismissal path.

## Official Apple API basis

Xcode MCP `DocumentationSearch` was used for the official SwiftUI `DismissAction` and XCTest `XCUIVoiceOverService` documentation. `DismissAction` is a `@MainActor`, `Sendable` action obtained from `EnvironmentValues.dismiss`; Apple documents that its behavior depends on the environment where it is read. The action is therefore read at the presented sheet root and passed explicitly to the pushed destination. `XCUIVoiceOverService` supplies the iOS 27 test-only VoiceOver enable, speech, navigation, and disable APIs used by the regression.

## Automated checks

| Check | Source | Result |
|---|---|---|
| Build for testing | Xcode MCP `BuildProject(buildForTesting: true)` | Pass |
| Add Drink UI regressions | Xcode MCP `RunSomeTests`: `drinkpulseUITests/AddDrinkFlowUITests` | Pass — 6/6 |
| Shell and VoiceOver regressions | Xcode MCP `RunSomeTests`: `drinkpulseUITests/ShellNavigationUITests` | Pass — 4/4 |
| Combined focused regression run | Xcode MCP `RunSomeTests` for both suites | Pass — 10/10 |

## Human check

**Result: pass.** On the selected iOS 27 simulator, the owner verified every changed Add Drink path:

- From a non-Home tab, grid Cancel returns to the originating tab.
- From a drink-detail screen, Cancel returns to the originating tab.
- Saving returns to the originating tab and preserves the new drink in History.
- The visible Cancel control has the expected semantic label and works with VoiceOver.

The owner also reported a separate pre-existing-or-uncertain Dashboard visual issue: after opening and closing Add Drink from Settings, then switching to Dashboard, Dashboard flashes for about one second. This observation is not recorded as an Add Drink acceptance failure; it is being reproduced and diagnosed separately before any source change.

No full-suite result is claimed.


## VoiceOver regression rewrite (gap closure D2)

**Date:** 2026-11-13 (plan 09-05, owner decision D2 "REWRITE", closes code-review finding WR-05 and verification warning D2)

**Problem:** the earlier test `test_voiceOver_cancelDismissesAddDrinkAndReturnsToHistory` called `voiceOver.disable()` before `cancel.tap()`, so the dismissal it asserted was a plain tap with VoiceOver off; it also had no availability guard and its name overclaimed.

**New test:** `ShellNavigationUITests/test_withVoiceOverRunning_focusCancelThenActivate_dismissesAddDrinkToOriginatingHistoryTab()`. With the VoiceOver service running, focus is moved onto Cancel with `moveForward()` (starting from `currentSpeech()`, at most 40 steps), Cancel is re-queried from the navigation bar, activated while the service stays enabled, and the test asserts that the Add Drink navigation bar disappears (message "Activating Cancel under VoiceOver should dismiss the Add Drink sheet") and that the History navigation bar is shown again.

### Official source and API availability

- Header `iPhoneOS.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Headers/XCUIVoiceOverService.h` (iOS 27.0+) shows `XCUIVoiceOverService` exposes only `enable()`, `disable()`, `isEnabled`, `moveForward()`, `moveBackward()`, `currentSpeech()`, `moveIn()`, and `moveOut()`. It has no activation method, so the review's suggested `performAction(.activate)` does not exist. Activation is therefore an `XCUIElement` gesture performed while the service stays enabled.
- Xcode MCP `DocumentationSearch` titles relied on: "XCUIVoiceOverService: Instance Methods" (the method list above, `enable()`/`disable()` described as "Enable VoiceOver."/"Disable VoiceOver."), "XCUIVoiceOverService.Output: Instance Properties" (`utterance`), "XCUIVoiceOverService: Instance Properties" (`isEnabled`), "doubleTap()" of `XCUIElement` ("Sends a double-tap event to a hittable point the system computes for the element."), "XCUIElement: Tapping and pressing", and "addTeardownBlock:" of `XCTestCase` (blocks run on the main thread, after the test method ends, last-in first-out, and cannot rethrow). `XCUIVoiceOverServiceError.h` defines `XCUIVoiceOverService.Error` with `failedToStart`, `notRunning`, `noSpeech`, `failedToStop`.

### Activation spike

| Route (preference order) | Observed result | Log |
|---|---|---|
| 1. `doubleTap()` on the re-queried Cancel button | Dismissed the sheet under a running VoiceOver service; Add Drink bar gone, History shown (1 passed, 0 skipped) | `build/d2-spike-doubletap.log` |
| 2. `tap()` on the re-queried Cancel button | Not attempted: route 1 succeeded, and the plan stops at the first working route | none |
| 3. normalized-centre coordinate `tap()` | Not attempted: route 1 succeeded | none |

The committed test uses route 1, `doubleTap()`, because the VoiceOver double-tap gesture activates the element that VoiceOver focus is on, and focus was just moved onto Cancel. The test name is route-neutral ("Activate"); this section records the gesture. The plain-tap control remains `test_dismissingAddDrink_returnsToPriorTab` (VoiceOver off).

### Skip guard and teardown design

- Exactly two `disable()` calls: one guarded call before `launchApp()` that normalizes a leftover enabled state, and one `try?` call in a single `addTeardownBlock` registered immediately before `enable()`. No `disable()` occurs between enabling the service and the final assertions.
- `enable()` runs in a do-catch; `XCUIVoiceOverService.Error.failedToStart` throws `XCTSkip`, every other error fails the test. A skip on the iOS 27.2 simulator used here would be a gate failure, because the service started there (and in 09-02).
- The semantic assertion that `navigationBars["Add Drink"].buttons["Cancel"]` exists before VoiceOver starts is retained.

### Results

| Run | Result | Log |
|---|---|---|
| Iteration 1 (iPhone 17, iOS 27.2) | 1 passed, 0 failed, 0 skipped | `build/d2-voiceover-1.log` |
| Iteration 2 | 1 passed, 0 failed, 0 skipped | `build/d2-voiceover-2.log` |
| Iteration 3 | 1 passed, 0 failed, 0 skipped | `build/d2-voiceover-3.log` |
| Whole `ShellNavigationUITests` class | 4 passed, 0 failed, 0 skipped | `build/d2-shell-class.log` |

### Mutation control

The grid toolbar Cancel action in `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift` was temporarily changed from `{ dismissSheet() }` to an empty closure. The new test then failed at `ShellNavigationUITests.swift:139` with `XCTAssertTrue failed - Activating Cancel under VoiceOver should dismiss the Add Drink sheet` (`build/d2-mutation.log`, `DP_RESULT status=failed`). The file was restored with `git checkout -- drinkpulse/Features/AddDrink/DrinkTypeGridView.swift`; `git status --porcelain -- drinkpulse` was empty and `git diff HEAD` on the file was empty (byte-identical) before the next step. The mutation was never committed.

### Xcode tooling record (owner decision O2)

| Log (`build/`, git-ignored) | Source header |
|---|---|
| `d2-spike-doubletap.log` | `xcode-mcp XcodeListRunDestinations GetTestList RunSomeTests GetBuildLog` |
| `d2-voiceover-1.log`, `d2-voiceover-2.log`, `d2-voiceover-3.log` | `xcode-mcp RunSomeTests GetBuildLog` |
| `d2-shell-class.log` | `xcode-mcp RunSomeTests GetBuildLog` |
| `d2-mutation.log` | `xcode-mcp RunSomeTests` |

No CLI `xcodebuild` step was used; every run went through Xcode MCP (`XcodeListWorkspaces` confirmed responsiveness; the active destination was already iPhone 17 (27.2), so `XcodeSwitchRunDestination` was not needed). `RunSomeTests` accepted the single-test identifier and the class identifier `ShellNavigationUITests`. Note: `GetTestList` (index of 816 tests) still listed the old test name next to the new one while the run executed only the new method; the class run reported exactly 4 tests.

### Limitation

The simulator test models VoiceOver activation with an `XCUIElement` double tap while the service runs. Real-device VoiceOver activation remains covered by owner UAT item 3 only.

## Addendum 2026-11-13 (plan 09-09)

The statement above that the Dashboard flash "is being reproduced and diagnosed separately before any source change" is stale: commit `553ea58` changed `DashboardView.swift` before any diagnosis, and plan 09-08 reverted that change. See `09-FLASH-DIAGNOSIS.md`, "Corrections to earlier records", for the correction, and its "Applied fix and automated verification" and "Owner deferral of D1 (2026-11-13)" sections for the current state (the flash is not fixed and is deferred). The text above is left as recorded.
