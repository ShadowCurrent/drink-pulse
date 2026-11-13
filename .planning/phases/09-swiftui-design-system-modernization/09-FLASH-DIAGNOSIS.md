# Phase 09: Cross-tab glass flicker after Add Drink dismissal (gap closure D1, plan 09-06)

Status: diagnosis in progress. No production source file is changed by plan 09-06. This file is the evidence record that decision C006 (`.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C006.md`) requires before any Liquid Glass change: a concretely measured defect, not an assumed one.

## Defect record

**Owner report, 2026-11-13 (translated from Polish):** after opening the Add Drink panel, closing it, and then switching to another tab, that view flashes or flickers for a moment. It is most visible on Insights and also happens on Dashboard. It does not happen every time, but almost every time, and not always equally strongly. It is clearly the glass cards and the glass-using elements that flicker.

Reading of the report: the flicker appears on at least two different tabs (Insights and Dashboard), so the common factor is something shared across tabs (the shell, the sheet presentation, or the `DPGlass` modifier), not a cause local to Dashboard. Insights has no `GlassEffectContainer`.

**Earlier report, 2026-09-18:** on an iPhone 15 Pro Max running iOS 27, Dashboard visibly flashed for approximately one second after every cycle of opening Add Drink, dismissing it, and switching to another tab. The iOS 27 simulator completed the same navigation flow correctly, but the first Xcode MCP static screenshot arrived after the artifact had elapsed. Commit `553ea58` ("fix(09): contain dashboard glass effects") wrapped the Dashboard card stack in `GlassEffectContainer(spacing: 0)` in response, and the issue persisted afterwards (pending todo `.planning/todos/pending/2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md`; DEVLOG entry 2026-09-18 21:15).

## Corrections to earlier records

- Commit `553ea58` changed `drinkpulse/Features/Dashboard/DashboardView.swift` before any diagnosis. That contradicts `09-ADD-DRINK-EVIDENCE.md` line 39 ("being reproduced and diagnosed separately before any source change"), the wording in `09-02-SUMMARY.md` and `09-UI-REVIEW.md` that the flash was only under reproduction, and the earlier verification claim that the flash was not expanded into this phase.
- The change was an unauthorized, unevidenced Liquid Glass change: no Phase 08 candidate authorizes it (UI-C-09 is Retain) and C006 permits a Liquid Glass change only for a specifically measured defect. It is the BLOCKER gap 1 in `09-VERIFICATION.md`.
- `09-VERIFICATION.md` is verifier-generated and is regenerated at re-verification, so it is not edited. The correction lives here, and the stale `09-ADD-DRINK-EVIDENCE.md` note receives a pointer to this file in plan 09-09.

## Planning provenance

- Probe fallback status: per `$HOME/.claude/gsd-core/references/specless-probe-fallback.md` section 0, the toggle defaults ON and any value other than a literal false enables it. This gap-closure planning ran the fallback with EDGE_ABSENT=1 and PROHIB_ABSENT=1. The earlier `09-RETAIN-EVIDENCE.md` value "disabled by project configuration" was recorded on 2026-09-19 and does not describe this planning pass.
- Flagged assumptions (unresolved edge probes, surfaced and not dropped):
  - Adjacency: glass cards sit 20 pt apart in VStacks and must not touch or merge; no diagnosis or fix variant changes card spacing or merges neighbouring glass shapes. Covered informally by the plan 09-10 owner visual checklist.
  - Empty store: the harness baseline and the owner session use seeded multiday data or the owner's populated store. The flash cause is assumed independent of data volume; when the data-dependence criteria below are met, plan 09-07 Task 1 runs the held-back empty-store harness test and records it before the C013 brief is finalized (or stops for the owner under Route D).
  - Ordering: no sorting or equal-element ordering is introduced or changed in this plan set; tab order (`AppTab`) is assumed unchanged.
- Prohibition (descriptor-less, flagged unverified): MUST NOT replace, remove, or redesign the centralized Liquid Glass layer (`DPGlass.swift` and its `glassEffect` consumers) as a workaround for the flash; diagnostic variants stay on local `diag/` branches and are never merged.

### Xcode tooling record

Owner decision O2 (2026-11-13): Xcode MCP is the first choice for builds, tests, simulator selection, and documentation. CLI `xcodebuild` is used only for a single step that needs a named capability the live Xcode MCP schema lacks. Each harness log under `build/` starts with a source header. Entries are added below as steps run.

| Step | Log | Source header | Missing capability and how the live schema showed it |
|---|---|---|---|

## Pre-registered decision rule

Written and committed before any measurement exists (commit R). No threshold below is adjusted after seeing data.

### Harness definition

`drinkpulseUITests/Features/Shell/SheetDismissTabSwitchUITests.swift` drives the owner's cycle on the iOS 27 simulator with the synthetic multiday dataset. A sheet-mode cycle taps Add Drink on the current tab, waits for the Add Drink navigation bar, taps Cancel, waits for it to disappear, taps the other tab (Home or Insights), and samples. A control cycle only taps the other tab and samples. Each run starts with an uncounted warm-up visit to Insights then Home, then 20 landings alternating Insights and Home (10 per tab). After each tab tap the harness waits for the destination navigation bar, then takes 8 `XCUIScreen.main.screenshot()` samples at 0.6, 0.8, ... 2.0 s after the tap and a settled reference at 3.0 s. Each screenshot is reduced to a 48 by 96 grayscale grid over the central band (the top 12 percent and bottom 12 percent are excluded to ignore the status bar and tab bar). The delta of a sample is the mean absolute grayscale difference to the settled reference on a 0 to 1 scale, and maxDelta is the maximum of the 8 deltas. Per landing the harness emits `DP_FLASH_METRIC mode=<sheet|control|empty-control|empty-sheet> landing=<Home|Insights> cycle=<n> maxDelta=<value> deltas=<list>` to the file named by `DP_FLASH_METRICS_PATH`, to standard output, and as a test attachment. The tests assert navigability only and never assert the flash metric. A third, held-back test runs the same cycle on an empty store for the conditional data-dependence measurement in plan 09-07.

### Decision rule

- T_ctrl for a tab is the largest maxDelta among the control landings on that tab.
- A sheet landing is an excursion when its maxDelta exceeds T_ctrl for that tab plus 0.02.
- Route S (the simulator reproduces) holds when at least 3 of the 10 sheet landings on at least one tab are excursions. Otherwise Route D (device-only).
- Owner-device counts out of 6 landings per tab are classified PRESENT when at least 3 landings on at least one tab flashed, ABSENT when at most 1 of 6 flashed on each tab, otherwise AMBIGUOUS.

### Threshold basis

- T_ctrl is the empirical noise floor: the largest maxDelta of the 10 no-sheet control landings on that tab, so it already absorbs the harness's own frame jitter.
- If sheet and control landings came from one distribution (no flash), the chance that at least 3 of the 10 sheet landings exceed the control maximum equals the chance that the 3 largest of 20 exchangeable values are all sheet values: (10/20)(9/19)(8/18), about 0.105 per tab. The 0.02 margin only lowers that figure.
- The 0.02 margin is an argued margin, not a measured one. On the 0 to 1 scale it is a mean change of about 5 of 255 grey levels across the whole central band. That is far below what a visible flash of the glass cards, which fill most of that band on Dashboard and Insights, produces, and it is enough to keep sub-visible compression or antialiasing differences just above the control maximum from counting.
- The count of 3 of 10 fits the owner's "almost every time" report: at a true per-landing flash rate of 0.5 or more, at least 3 of 10 excursions occur with probability above 0.94.
- On the device, PRESENT at 3 or more of 6 is half the landings. ABSENT at 1 or fewer of 6 tolerates one misjudged landing in human observation. 2 of 6 is AMBIGUOUS by construction, so no conclusion rests on a single landing.

### Data-dependence criteria

The rule plan 09-07 applies. Data dependence is shown when either:

1. the narrowest responsible layer from the verdicts, or the mechanism of a supported hypothesis, is view content whose rendering inputs come from the store (a view model or query load that runs when the tab appears, or chart or card content derived from logged drink events) rather than the shell sheet presentation, the Add Drink sheet content, or the DPGlass modifier; or
2. under Route S the owner device session classifies a tab PRESENT while the multiday simulator baseline shows at most 1 excursion of 10 on that tab.

Otherwise data dependence is not shown. When it is shown, the empty-store harness test runs and is recorded before the C013 brief is finalized.

## Harness shake-down findings (after commit R, before any measurement)

Added after commit R and before any baseline measurement. These runs only exercised the harness; none of their frame values are used, and no threshold above changed.

Finding: on HEAD (Debug, iPhone 17, iOS 27.2 simulator) the app crashes inside the Add Drink sheet cycle. The crash is deterministic in the sheet cycle and absent from the no-sheet control.

| Run (local time 2026-11-13) | Test and dataset | Result |
|---|---|---|
| 15:08 | sheet cycle, multiday | 2 landings completed, app crashed during the tab switch of cycle 3 |
| 15:10 | sheet cycle, multiday | 1 landing completed, app crashed during the tab switch of cycle 2 |
| 15:11 | no-sheet control, multiday | passed, all 20 landings, no crash |
| 15:14 | sheet cycle, multiday, screenshot sampling removed (temporary local edit, reverted, not committed) | app crashed after 3 Cancel taps, so sampling is not the trigger |
| 15:15 | empty-store test | all 20 empty-control landings completed; app crashed in the empty-sheet phase after 2 Cancel taps, so the store contents are not the trigger |
| 15:19 | existing `ShellNavigationUITests` Add Drink tests (2 tests) | passed, so the simulator environment is healthy |

Crash signature (macOS crash reports from 15:10, 15:11, 15:15, and 15:18, kept outside the repository; they contain no drink or profile data): `EXC_BREAKPOINT (SIGTRAP)` on the main thread, top frames in private `DesignLibrary` (no symbols), then `SwiftUICore` `MaterialProviderBox.resolveLayers(in:)`, `GlassEffectResolvedMaterial.value.getter`, an `Attribute.init` closure, AttributeGraph updates, `ViewGraph.updateOutputsAsync`, display-link render. No drinkpulse frame is on the faulting thread. These are the only `drinkpulse` crash reports on this machine, all produced by the new sheet-cycle runs.

Reading: the crash sits in the same Liquid Glass material resolution path the owner's flicker involves (the glass cards), and it occurs on the same cycle (Add Drink, Cancel, tab switch). Whether it is the same mechanism as the device flicker, a simulator-only trap, or an unrelated defect is not established. It is recorded as a separate finding for plan 09-07 and is not a conclusion.

Consequence for the protocol: the unmodified harness cannot complete 20 sheet landings on HEAD, so the Task 1 gate (both baseline tests passing) cannot be met as written. A protocol decision is required before the baseline is measured.

## Baseline results
