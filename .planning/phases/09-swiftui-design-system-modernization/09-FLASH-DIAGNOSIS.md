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

## Crash isolation (owner decision B, 2026-11-13)

Owner decision "B: crash first" (2026-11-13): the frame-delta measurement is paused. No baseline measurement is taken, no baseline commit is written, and neither the thresholds nor the decision rule above change. The crash on HEAD is isolated first so plan 09-07 can be re-planned around it. This section is written and committed before any crash-isolation result exists.

### Apple documentation consulted (Xcode MCP DocumentationSearch, 2026-11-13)

| Document (title) | Statement relied on |
|---|---|
| `glassEffect(_:in:)` (SwiftUI, View) | The system renders a shape anchored behind the view with the Liquid Glass material and applies foreground effects over the view; the glass anchors to the view bounds. The modifier is typically used with a `GlassEffectContainer`. |
| `GlassEffectContainer` (SwiftUI) | A container combines multiple Liquid Glass shapes so SwiftUI renders them together, which "improves rendering performance" and lets shapes blend and morph. The same title's overview and "Applying Liquid Glass to custom views" say a container spacing larger than the interior stack spacing makes the shapes blend at rest. |
| `dismiss` / `DismissAction` (SwiftUI) | Calling the dismiss action from the sheet's own environment dismisses the presentation. This is how the harness Cancel path (and the trivial-sheet variant) closes the sheet. |
| `sheet(isPresented:onDismiss:content:)`, `TabView`, `Tab` (SwiftUI index entries) | Search returned only API index entries. No statement about how a sheet presented over tab content interacts with glass effects in that content, and no statement about a crash or a trap in glass material resolution, was found. |

Consequence: the official documentation consulted neither predicts nor explains the crash. The hypotheses below are therefore falsifiable guesses about which code the crash depends on, to be decided by the variants, not by documentation. No skill or third-party source is used.

### Crash facts fixed before the variants run

- Signature on HEAD (iPhone 17, iOS 27.2 simulator, Debug): `EXC_BREAKPOINT` on the main thread inside private `DesignLibrary`, `SwiftUICore` `MaterialProviderBox.resolveLayers(in:)`, `GlassEffectResolvedMaterial.value.getter`, AttributeGraph; no drinkpulse frame.
- Reproduces in the sheet cycle (Add Drink, Cancel, tab switch) at cycle 2 to 3 of 20, with and without screenshot sampling, with a seeded and an empty store. The no-sheet control passed 20 of 20 landings. `ShellNavigationUITests` Add Drink tests pass.

### Crash hypotheses and predictions

Variants are the plan's Task 2 variants, created from harness commit `010a843`: V1 `diag/09-flash-v1-no-container` (Dashboard container removed), V3 `diag/09-flash-v3-trivial-sheet` (sheet content replaced by a minimal Add Drink NavigationStack with a Cancel button), V4 `diag/09-flash-v4-material` (every `dpGlassCard` uses a regular material background instead of `glassEffect`). C means the app crashed before 20 landings; N means the sheet-mode test completed 20 landings without a crash.

| ID | Hypothesis | V1 | V3 | V4 |
|---|---|---|---|---|
| CH1 | The Dashboard `GlassEffectContainer(spacing: 0)` from commit 553ea58 is required for the crash. | N | C | N |
| CH2 | The Add Drink sheet content (its own glass tiles, `DrinkTypeTile`) is required for the crash. | C | N | N |
| CH3 | Glass effects in the tab content, together with presenting and dismissing any sheet, are sufficient; neither the container nor the Add Drink content is required. | C | C | N |
| CH4 | Presenting and dismissing a sheet over the TabView is sufficient regardless of glass. | C | C | C |
| CH5 | Both the container and the sheet content's glass are required (interaction). | N | N | N |

- A hypothesis is supported only when every one of its three predictions holds. Any pattern not listed is reported as unclassified, with the raw per-variant results.
- Rule for each variant run: one run of the harness sheet-mode test (`test_sheetCancelThenTabSwitch_cycle_staysNavigable_recordsFrameDeltas`) on the iPhone 17 iOS 27.2 simulator. C on any crash or app-termination failure; N only when all 20 landings complete. An infrastructure failure (the simulator did not boot, a build error, a tool timeout) is not a result; the run is repeated. HEAD crashed in 4 of 4 sheet runs at cycle 2 or 3, so a clean 20 landings is strong evidence for N.
- CH6 (qualifier, not discriminable by the variants): the crash is specific to the iOS 27.2 simulator rendering path and does not occur on the owner's iPhone 15 Pro Max, where the owner reports flicker and no crash. The simulator evidence cannot confirm or reject CH6; any conclusion drawn here is simulator evidence only.
- Optional minimal-repro check: run only if the variants leave the pattern unclassified or CH3/CH4 as the supported reading. A new throwaway `diag/` branch with an app of one TabView, glass cards in the tab content, and one sheet with a Cancel button. Predictions: CH3 supported implies the minimal repro crashes; CH4 supported implies a minimal repro without glass crashes.

### Crash isolation results

Variants were created as one commit each on local branches in git worktrees outside the repository, from harness commit `010a843`, after the hypotheses commit `df74b25`. They are never merged, cherry-picked, or pushed. Each ran the pre-registered single run of the harness sheet-mode test on the iPhone 17 (iOS 27.2) simulator through Xcode MCP (`XcodeOpenWorkspace` on the worktree project as its own window, `XcodeSwitchRunDestination`, `BuildProject` with `buildForTesting`, `RunSomeTests`), each window closed afterwards. No CLI step was used. The first `RunSomeTests` call in a freshly opened worktree window returned "not found in target" until `BuildProject` with `buildForTesting` had run once (the UI test target is absent from `GetTestList` before that build). Logs under the git-ignored `build/` directory: `flash-crash-V1.log`, `flash-crash-V3.log`, `flash-crash-V4.log`, each with its source header and `DP_RESULT` line.

| Variant | Branch and commit | Change against harness commit `010a843` | Result (2026-11-13, local time) | Landings completed | Crash signature (frames only) |
|---|---|---|---|---|---|
| V1 | `diag/09-flash-v1-no-container` `e2b2546` | `DashboardView.swift` restored to its form before commit 553ea58 (the `GlassEffectContainer(spacing: 0)` wrapper removed) | C, 15:30 | 1 of 20 (crashed in cycle 2) | Same as HEAD: `EXC_BREAKPOINT`, private `DesignLibrary`, `MaterialProviderBox.resolveLayers(in:)`, `GlassEffectResolvedMaterial.value.getter`, AttributeGraph |
| V3 | `diag/09-flash-v3-trivial-sheet` `5c37b22` | `RootShellView.swift`: sheet content replaced by a minimal `NavigationStack` titled "Add Drink" with a Cancel button that calls `dismiss()` | C, 15:32 | 1 of 20 (crashed in cycle 2) | Same as HEAD (identical frames) |
| V4 | `diag/09-flash-v4-material` `2442fdb` | `DPGlass.swift`: `.glassEffect(.regular, in: ...)` replaced by `.background(.regularMaterial, in: ...)` for every `dpGlassCard` consumer | N, 15:33 | 20 of 20, test passed | none; no new crash report |

HEAD reference from the shake-down above: crashed in 4 of 4 sheet runs at cycle 2 or 3, no-sheet control 20 of 20 without a crash. Crash reports for V1 and V3 are kept outside the repository (`drinkpulse-2026-11-13-153132.ips`, `drinkpulse-2026-11-13-153311.ips`); frames only are recorded here. No `DP_FLASH_METRIC` frame value from these runs is used as a flash measurement; the frame deltas of the completed V4 landings are not analysed here.

Hypothesis check against the pre-registered table:

| ID | Predicted V1, V3, V4 | Observed C, C, N | Verdict |
|---|---|---|---|
| CH1 container required | N, C, N | V1 is C | Falsified |
| CH2 Add Drink sheet content required | C, N, N | V3 is C | Falsified |
| CH3 glass in tab content plus any sheet is sufficient | C, C, N | matches | Supported |
| CH4 sheet over TabView alone, regardless of glass | C, C, C | V4 is N | Falsified |
| CH5 container and sheet glass both required | N, N, N | V1 is C | Falsified |
| CH6 simulator-only | not discriminable | not discriminable | Open |

Reading, stated as simulator evidence only: the crash needs `glassEffect` material resolution in the app's glass cards together with the Add Drink then Cancel sheet cycle. It does not need the Dashboard container, and it does not need the Add Drink sheet's own content, because a sheet with no glass still triggers it. Replacing the glass with a material removes it. The no-sheet control passes with the same glass cards present, so the sheet present-and-dismiss cycle is part of the trigger. Limits of this evidence:

- One run per variant, as pre-registered. The two crashing variants crashed within 2 cycles like HEAD, so the contrast with 20 clean landings in V4 is large, but it is still one run each.
- V4 replaces the glass in every consumer at once, so this round does not say which tab, which card, or which view's glass is the trigger. The tab landing that crashes is not recorded.
- The minimal-repro check was not run. The variants discriminate, and a standalone repro is an owner-prioritised follow-up rather than a protocol step.
- CH6 stays open: the owner's device reports flicker, not a crash, so a simulator-only trap in iOS 27.2 simulator glass rendering cannot be excluded or confirmed here.
- Which hypothesis explains the device flicker is not established. The crash and the flicker share the cycle and the glass material path; that is a lead, not a link.

## Crash isolation round 2 (owner decision C, 2026-11-13)

Owner decision "C only" (2026-11-13): run a second simulator bisect round that narrows the crash to the smallest responsible view, plus a standalone minimal repro suitable for an Apple Feedback report, then stop for another owner decision before any device session. The frame-delta baseline, commit H, thresholds, the pre-registered decision rule, the device session, and production source stay untouched. This section is written and committed before any round-2 run exists.

### Apple documentation consulted for round 2 (Xcode MCP DocumentationSearch, 2026-11-13)

| Document (title) | Statement relied on |
|---|---|
| `glassEffect(_:in:)` (SwiftUI, View) | `nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View`. The system renders a shape anchored behind the view with the Liquid Glass material and applies foreground effects over the view; the glass anchors to the view bounds. Typically used with a `GlassEffectContainer`. Used unchanged in the minimal repro, with `.rect(cornerRadius:)` as in `DPGlass.swift`. |
| "Applying Liquid Glass to custom views" (SwiftUI article) | `glassEffect` defaults to the `regular` variant; examples use `in: .rect(cornerRadius:)`. A container is advised "when applying Liquid Glass effects on multiple views to achieve the best rendering performance"; it is a recommendation, not a requirement. No statement about a sheet presented over glass content. |
| `Glass` (SwiftUI) | `Glass.regular` is the regular variant of the Liquid Glass material; `.clear` and `.identity` exist. Round 2 uses `.regular` only, like the app. |
| `TabView`, `Tab` (SwiftUI) | `TabView(selection:)` with `Tab(_:systemImage:value:)` is the programmatic-selection form; the minimal repro uses it with one `NavigationStack` per tab, like `RootShellView`. |
| `toolbarVerticalCompressionBehavior(_:)` example (SwiftUI) | Confirms the documented pattern `TabView { Tab { NavigationStack { content.toolbar { ... } } } }` for toolbar items inside tabs. |

Consequence, as in the first round: the documentation neither predicts nor explains the crash; the predictions below are falsifiable guesses about which code the crash depends on. No skill or third-party source is used.

### Facts carried from round 1 (simulator evidence only)

HEAD, V1, and V3 crash in the sheet cycle (Add Drink, Cancel, tab switch) at cycle 2 or 3; V4 (every `dpGlassCard` uses a regular material) completes 20 of 20; the no-sheet control completes 20 of 20. Production glass call sites that can render in the harness (the harness only visits Home and Insights; History and Settings are never selected, so their `dpGlassCard` sites in `HistoryCalendarView.swift` and `SettingsSection.swift` are outside this bisect, and `AlcoholAreaChart.swift` line 164 is inside a `#Preview` and not production):

| Tab | Call sites (one `dpGlassCard` each) |
|---|---|
| Home (Dashboard, inside `GlassEffectContainer(spacing: 0)` as at HEAD) | `DashboardHeroCard`, `DPChip` (two instances in `DashboardChipRow`), `ConsumptionOverviewCard`, `ThisWeekCard`, `StreakCard` (two instances), `GuidelineAlertCard` (only when the risk level is exceeded) |
| Insights (no container) | `InsightsScopeNavigator`, `InsightsHeroCard`, `HealthMetricsCard`, `WeekdayBarChart`, `GuidelineComparisonCard` |
| Add Drink sheet | `DrinkTypeTile` (V3 showed the sheet's glass is not needed for the crash) |

### Variant construction

Each variant is one commit on a new local branch `diag/09-crash-r2-<name>` in its own git worktree `/Users/fempter/Developer/drinkpulse-diag/r2-<name>`, created from harness commit `010a843`; never merged, cherry-picked, or pushed. Every variant carries the same two base changes plus its own site selection:

1. Base change B1 (`DPGlass.swift`): `dpGlassCard` uses `.background(.regularMaterial, in: .rect(cornerRadius:))` exactly as V4; a new modifier `dpGlassCardLive` applies the unchanged HEAD call `.glassEffect(.regular, in: .rect(cornerRadius: size.cornerRadius))`.
2. Site selection: in the files named for the variant, `.dpGlassCard(` is replaced by `.dpGlassCardLive(`. All other sites keep the V4 material. `DashboardView.swift` keeps the `GlassEffectContainer(spacing: 0)` exactly as at HEAD in every variant (CH1 was falsified, so the container is not a variable here).
3. Base change B2 (diag-only harness instrumentation, in the variant commit only; the committed harness on the working branch is unchanged): `print` lines `DP_FLASH_PHASE cycle=<n> step=<cycle-start|sheet-shown|sheet-dismissed|tab-tapped|landed> presenting=<Home|Insights> target=<Home|Insights>` at those five points of each cycle. No sampling, wait, or assertion changes. The last phase line before a crash records the landing, the tab, and the cycle, and identifies the step: a crash after `sheet-dismissed` and before `tab-tapped` is on the tab switch, after `tab-tapped` and before `landed` is on the landing, after `landed` is during sampling. Cycle k is odd when the sheet is opened on Home and the target is Insights, even when it is opened on Insights and the target is Home.

### Run protocol (round 2)

- One run is the harness sheet-mode test (`test_sheetCancelThenTabSwitch_cycle_staysNavigable_recordsFrameDeltas`) on the iPhone 17, iOS 27.2 simulator through Xcode MCP: `XcodeOpenWorkspace` on the worktree project as its own window, `XcodeSwitchRunDestination`, `BuildProject` with `buildForTesting`, `RunSomeTests`, each window closed afterwards. CLI only for a named missing capability, recorded in the Xcode tooling record.
- A variant is C when the app crashes before 20 landings in any run. A variant is N only when two separate runs both complete 20 landings. (Round 1 accepted one clean run because HEAD crashed 4 of 4 times; the narrower variants may crash less often, so round 2 asks for two clean runs before an N is accepted.) An infrastructure failure (simulator did not boot, build error, tool timeout) is not a result and the run is repeated.
- Logs: `build/flash-crash-r2-<name>.log` with the source header, `DP_RESULT` line, and the `DP_FLASH_PHASE` lines; crash reports are kept outside the repository and only frames are recorded.
- Frame-delta values of completed landings are not analysed.

### Stage 1: per-tab variants

| Variant | Live glass (`dpGlassCardLive`) | Material (everything else) |
|---|---|---|
| `r2-dash` | all Dashboard call sites listed above | Insights, History, Settings, Add Drink sheet |
| `r2-ins` | all Insights call sites listed above | Dashboard, History, Settings, Add Drink sheet |

Hypotheses (outcome pairs are for `r2-dash`, `r2-ins`; a hypothesis is supported only when both predictions hold; other pairs are unclassified):

| ID | Hypothesis | `r2-dash` | `r2-ins` |
|---|---|---|---|
| RH1 | Glass on Home alone is sufficient; Insights glass is not | C | N |
| RH2 | Glass on Insights alone is sufficient; Home glass is not | N | C |
| RH3 | Glass on either tab alone is sufficient (a shared mechanism, not one tab's view) | C | C |
| RH4 | Glass on both tabs is required (cross-tab interaction), or the trigger is glass the stage-1 variants removed from non-harness surfaces | N | N |

If the outcome is RH4 (N, N), run one more variant `r2-both` (live glass at all Dashboard and Insights call sites, material at History, Settings, and the Add Drink sheet) under the same protocol: C means glass on both visited tabs is required together; N means the trigger depends on glass at History, Settings, or the sheet tile and the bisect stops there for the owner.

Descriptive hypotheses about the crashing step, evaluated only on single-tab variants that crash, from the last `DP_FLASH_PHASE` line before the crash:

| ID | Hypothesis | Prediction |
|---|---|---|
| RH5 | The crash occurs when the tab whose glass is live becomes the target of the tab switch | the crashing cycle has `target` equal to the live-glass tab |
| RH6 | The crash occurs when the tab whose glass is live is the tab that presented the sheet | the crashing cycle has `presenting` equal to the live-glass tab and `target` equal to the other tab |

Neither is a pre-condition for the bisect; if the crashing cycles are mixed, both are reported as not supported.

### Stage 2: per-card bisect within a responsible tab

Run on every tab whose stage-1 variant was C. Sites are halved in the fixed order below; only the first half is run first. If the first half is C, the search continues inside it and the second half is not claimed. If the first half is N (two clean runs), the second half runs. If both halves are N, the trigger needs several sites of that group together (interaction): the search stops at that group and the group is reported as the narrowest responsible unit. The result is the narrowest sufficient view found; it does not claim that other sites are insufficient unless they were run. A variant named `r2-<tab>-<sites>` uses live glass only at the named sites and material everywhere else.

| Tab | Level 1 first half | Level 1 second half | Level 2 and level 3 order |
|---|---|---|---|
| Home | A = `DashboardHeroCard`, `DPChip`, `ConsumptionOverviewCard` | B = `ThisWeekCard`, `StreakCard`, `GuidelineAlertCard` | for a 3-site group: first site alone, then the other two together, then those two one at a time (listed order) |
| Insights | A = `InsightsScopeNavigator`, `InsightsHeroCard` | B = `HealthMetricsCard`, `WeekdayBarChart`, `GuidelineComparisonCard` | for a 2-site group: first site alone, then the second; for a 3-site group as for Home |

Budget: at most 8 stage-2 variants in total. If the budget is reached before the search ends, the search stops and the remaining ambiguity is reported. Stage-2 predictions are not enumerated per variant; the rule above is the pre-registration, and any C or N is interpreted only through it. `GuidelineAlertCard` renders only when the risk level is exceeded; if the multiday dataset does not render it, a result for a group containing it applies to the sites that rendered, and this is recorded.

### Minimal repro (standalone, outside the repository)

A tiny SwiftUI iOS 27 app at `/Users/fempter/Developer/drinkpulse-diag/minimal-repro` (not a git worktree of this repository, no SwiftData, no app data, no personal data, no third-party code), with a UI test target. Apple documentation sources are the entries consulted above. Created and run through Xcode MCP (`XcodeNewProject`, `XcodeOpenWorkspace`, `BuildProject`, `RunSomeTests`).

- MR1 (baseline repro): `TabView(selection:)` with two tabs, Home and Insights; each tab is a `NavigationStack` with a `ScrollView` and a `VStack(spacing: 20)` of six text cards, each with `.glassEffect(.regular, in: .rect(cornerRadius: 24))` (no container); each tab has a toolbar `Button` "Add Drink" (trailing) that sets a `@State` flag on the shell; one `.sheet(isPresented:)` on the `TabView` shows a `NavigationStack` titled "Add Drink" with a Cancel button calling `dismiss()`. The UI test performs a warm-up visit Insights then Home, then 20 alternating landings of Add Drink, Cancel, tap the other tab, then a 3 s dwell (no screenshot sampling).
- MR1-control: MR1 with every `.glassEffect(...)` replaced by `.background(.regularMaterial, in: .rect(cornerRadius: 24))`. Run only if MR1 crashes.
- MR2 (one escalation, only if MR1 completes 20 landings in two runs): MR1 plus the distinguishing features of the narrowest responsible view named by stage 2 (for example a Swift Charts `Chart` inside the glass card, or the same container, or the same view structure), chosen after the stage-2 result and described in the results before it is run. No further escalation.

Predictions: CH3 in its strong form (glass in tab content plus a sheet cycle is sufficient, independent of app content) predicts MR1 crashes, with the same signature (`EXC_BREAKPOINT` in private `DesignLibrary`, `MaterialProviderBox.resolveLayers(in:)`, `GlassEffectResolvedMaterial.value.getter`) and MR1-control completes 20 of 20. If MR1 is N in two runs, the trigger depends on app-specific content and MR2 tests that. MR1 counts as crashed on any crash before 20 landings in any run; as N only after two clean runs.

If MR1 or MR2 crashes with the same signature, draft Feedback text (title, steps, expected and actual, environment) in the results section; nothing is submitted. All round-2 evidence is simulator evidence; CH6 (simulator-only) cannot be settled here and stays open.

### Stop condition

After the results are committed (a later commit than this one), all diagnostic Xcode windows are closed, only the main workspace is open, the working branch is confirmed clean and not on a `diag/` branch, and a decision checkpoint is returned. No device session, no baseline, and no source change on the working branch happen in this round.

## Baseline results
