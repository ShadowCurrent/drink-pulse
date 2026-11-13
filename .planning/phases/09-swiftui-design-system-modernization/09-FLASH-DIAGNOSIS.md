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
| Crash isolation round 1, V1/V3/V4 (worktrees `v1`, `v3`, `v4`) | `build/flash-crash-V1.log`, `-V3.log`, `-V4.log` | `# source: xcode-mcp XcodeOpenWorkspace XcodeSwitchRunDestination BuildProject RunSomeTests` | none |
| Round 2 stage 1, `r2-dash` and `r2-ins` (one worktree each, closed after the run) | `build/flash-crash-r2-dash.log`, `build/flash-crash-r2-ins.log` | `# source: xcode-mcp XcodeOpenWorkspace XcodeSwitchRunDestination BuildProject RunSomeTests` | none. Each new project path needed a one-time Xcode MCP permission approval from the owner; the first `RunSomeTests` identifier must end in `()` (`GetTestList` shows the form). |
| Round 2 stage 2, `dash-A`, `dash-A1`, `ins-A`, `ins-A1` (one reused worktree path, later removed; `-derivedDataPath` under `drinkpulse-diag/dd/`, simulator id of the iPhone 17 iOS 27.2) | `build/flash-crash-r2-dash-A.log`, `-dash-A1.log`, `-ins-A.log`, `-ins-A1.log` | `# source: cli-xcodebuild missing-mcp-capability=worktree-project-outside-open-workspace` | Owner-directed 2026-11-13 after the stage-1 permission prompts: no further new project paths were opened in Xcode, so these four variants ran through CLI `xcodebuild test -only-testing:`. The AGENTS.md worktree exception also applies (`mcpbridge` acts on the project open in Xcode). |
| Minimal repro compile check (before the stable-path update) | none kept | CLI `xcodebuild build-for-testing` | Compile check only; no test result comes from it. |
| Minimal repro MR1 and MR1-control (stable path `/Users/fempter/Developer/drinkpulse-diag/minimal-repro`, one window, closed afterwards) | `build/flash-crash-r2-minimal-MR1.log`, `build/flash-crash-r2-minimal-MR1-control.log` | `# source: xcode-mcp XcodeOpenWorkspace XcodeSwitchRunDestination BuildProject RunSomeTests` | none |
| Plan 09-07 Task 1 (evidence classification and C013 brief; no build or test run) | none | Apple documentation only, through Xcode MCP `DocumentationSearch` | none; no CLI step was used |

Stable-path setup (owner update, 2026-11-13): one detached worktree `/Users/fempter/Developer/drinkpulse-diag/work` (created at harness commit `010a843`) was prepared as the single path for further variants. After the update no further variant was needed, so it was never opened in Xcode and is unused. The `r2-dash`, `r2-ins`, and reused `r2-work` worktree paths created earlier in round 2 are removed (their branches are kept); `v1`, `v3`, `v4` are untouched. This is a path-management deviation from the pre-registered "own worktree per variant"; every variant is still one commit on its own local `diag/09-crash-r2-*` branch from `010a843`.

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

## Crash isolation round 2 results (2026-11-13)

Written after every round-2 run and after the pre-registration commit `0cdb397`. All evidence is from the iPhone 17 iOS 27.2 simulator (Xcode 27.2, build 27B52); none of it is device evidence. Variants are one commit each on local branches from harness commit `010a843`, never merged or pushed. Crash reports (macOS `.ips`, no drink or profile data) are kept outside the repository under `/Users/fempter/Developer/drinkpulse-diag/crash-reports/`; only frames are recorded here. Every crash had the same signature as HEAD: `EXC_BREAKPOINT` on the main thread, private `DesignLibrary`, `SwiftUICore` `MaterialProviderBox.resolveLayers(in:)`, `GlassEffectResolvedMaterial.value.getter`, AttributeGraph, `ViewGraph.updateOutputsAsync`. `build/` logs are git-ignored.

Each variant's change against `010a843`: base change B1 (`dpGlassCard` is a regular material, new `dpGlassCardLive` is the unchanged HEAD `glassEffect` call) and B2 (`DP_FLASH_PHASE` print lines in the diag harness copy), plus `.dpGlassCard(` to `.dpGlassCardLive(` at the named sites only.

### Stage 1 and stage 2 results (single run each; every result is C, so the two-run N rule was never needed)

| Variant | Branch and commit | Live glass sites | Result | Landings completed | Last phase line before the crash |
|---|---|---|---|---|---|
| `r2-dash` | `diag/09-crash-r2-dash` `25747af` | all 6 Dashboard sites | C | 3 | cycle 4, `tab-tapped`, presenting Insights, target Home |
| `r2-ins` | `diag/09-crash-r2-ins` `8226b87` | all 5 Insights sites | C | 2 | cycle 3, `tab-tapped`, presenting Home, target Insights |
| `dash-A` | `diag/09-crash-r2-dash-A` `5a9ca1e` | `DashboardHeroCard`, `DPChip`, `ConsumptionOverviewCard` | C | 7 | cycle 8, `tab-tapped`, presenting Insights, target Home |
| `dash-A1` | `diag/09-crash-r2-dash-A1` `d72feee` | `DashboardHeroCard` only | C | 3 | cycle 4, `tab-tapped`, presenting Insights, target Home |
| `ins-A` | `diag/09-crash-r2-ins-A` `c3807ee` | `InsightsScopeNavigator`, `InsightsHeroCard` | C | 2 | cycle 3, `tab-tapped`, presenting Home, target Insights |
| `ins-A1` | `diag/09-crash-r2-ins-A1` `a180983` | `InsightsScopeNavigator` only | C | 6 | cycle 7, `tab-tapped`, presenting Home, target Insights |

Hypothesis check against the pre-registered tables:

| ID | Prediction | Observed | Verdict |
|---|---|---|---|
| RH1 Home glass alone sufficient, Insights not | `r2-dash` C, `r2-ins` N | C, C | Falsified |
| RH2 Insights glass alone sufficient, Home not | N, C | C, C | Falsified |
| RH3 glass on either tab alone is sufficient | C, C | C, C | Supported |
| RH4 glass on both tabs required | N, N | C, C | Falsified (`r2-both` not needed) |
| RH5 crash when the live-glass tab is the target of the tab switch | target equals the live-glass tab | all six crashes: target is the live-glass tab | Supported |
| RH6 crash when the live-glass tab presented the sheet | presenting equals the live-glass tab | all six crashes: presenting is the other tab | Not supported |

Stage 2 stopped by its own rule: on Home the first half crashed, then its first site alone crashed (`DashboardHeroCard`); on Insights the first half crashed, then its first site alone crashed (`InsightsScopeNavigator`). The 8-variant budget was not reached (4 used). Second halves and the other single sites were not run, so no claim is made that they are insufficient.

### Narrowest responsible view (simulator evidence)

One live `glassEffect` card suffices on either visited tab: `DashboardHeroCard` on Home and `InsightsScopeNavigator` on Insights. In all six crashing runs the last phase line is `tab-tapped` for the tab holding the live glass; no crash happened after `landed`, during sampling, at sheet presentation, or at sheet dismissal. The crash is therefore at the first update after a tab switch lands on a tab containing a live glass card, after an Add Drink then Cancel sheet cycle. Cycles survived before a crash vary (2 to 7), and the earlier landings on the glass tab in the same run completed (for example `dash-A1` landed on Home in cycle 2), so the trigger is intermittent and not every glass landing after a sheet cycle crashes. The Dashboard container, the Add Drink sheet content, and card variety are not required (round 1 plus this round). Which property of a single card matters (its content, its position in a `ScrollView`, being the first glass card) is not narrowed further; a landing on a tab with several glass cards is not shown to crash more often (the single-card variants crashed at cycles 3 to 8, the all-glass HEAD at cycles 2 to 3, but with one run each this is not a rate comparison).

### Minimal repro (`/Users/fempter/Developer/drinkpulse-diag/minimal-repro`, outside the repository, no app data)

Built as designed in the pre-registration: `TabView(selection:)` with two tabs, each a `NavigationStack` with a `ScrollView` of six `Text` cards using `.glassEffect(.regular, in: .rect(cornerRadius: 24))` and no container, a toolbar "Add Drink" button on each tab, one `.sheet` on the `TabView` with a "Cancel" button calling `dismiss()`, and a UI test that cycles 20 times (Add Drink, Cancel, other tab, 3 s dwell). The project was written by hand (a synchronized-folder project, shared scheme, no third-party code), not from a template, so that it stays a handful of files. Control launch argument `-mr_material` swaps the glass for `.background(.regularMaterial, in: .rect(cornerRadius: 24))`.

| Run | Variant | Result | Detail |
|---|---|---|---|
| 1 | MR1 glass | clean, 20 of 20 | `MR_DONE landings=20`, 261 s |
| 2 | MR1 glass | infrastructure error, not a result | "The result bundle could not be opened as it is incomplete"; repeated |
| 3 | MR1 glass | C | crashed in cycle 7 (last line: `tab-tapped`, target Insights, after the sheet was presented on Home and dismissed); same signature: `EXC_BREAKPOINT`, private `DesignLibrary`, `MaterialProviderBox.resolveLayers(in:)`, `GlassEffectResolvedMaterial.value.getter`, AttributeGraph, `ViewGraph.updateOutputsAsync` |
| 4, 5 | MR1-control (material) | clean, 20 of 20 each | `MR_DONE landings=20` in both |

Reading: the minimal repro reproduces the crash with the same signature, in 1 of 2 completed glass runs, and the material control completed in 2 of 2 runs, as CH3 in its strong form predicted. The crash is intermittent in the repro as in the app, so a clean glass run does not clear a build. MR2 (escalation) was not needed.

### What is still open

- CH6 stays open: the crash is simulator evidence only. The owner's iPhone 15 Pro Max reports flicker and no crash. Whether the flicker is the same glass-resolution path failing softly on device, or an unrelated device-only symptom, is not established. The minimal repro offers the cleanest next test: the same MR1 UI test run on the owner's device in a Debug build tells whether the repro flickers or crashes there, and it needs no app data.
- The crash rate is not measured: one run per variant (all C) says the variants crash, not how often; the clean first MR1 run shows runs can pass.
- Why one card suffices, and what property triggers it, is not narrowed (see above). Whether the device flicker maps to the narrowed site is not established.
- Frame-delta evidence for the flicker (decision rule, thresholds, baseline) is untouched and unmeasured.

### Draft Feedback text (not submitted)

Title: SwiftUI: crash (EXC_BREAKPOINT in GlassEffectResolvedMaterial.value.getter / MaterialProviderBox.resolveLayers) when switching tabs after presenting and cancelling a sheet over a TabView with glassEffect cards (iOS 27.2 simulator)

Steps:
1. Build a SwiftUI app with a `TabView(selection:)` of two `Tab`s, each a `NavigationStack` containing a `ScrollView` with six `Text` cards, each styled with `.glassEffect(.regular, in: .rect(cornerRadius: 24))` (no `GlassEffectContainer`). Add a toolbar "Add Drink" button to each tab that sets a `@State` flag, and one `.sheet(isPresented:)` on the `TabView` whose content is a `NavigationStack` with a Cancel button calling `dismiss()`.
2. Run on the iPhone 17 iOS 27.2 simulator (Debug).
3. Repeat: tap "Add Drink", tap Cancel, tap the other tab, wait 3 s. Alternate the tabs.

Expected: the tab switch completes and the app keeps running.
Actual: intermittently the app terminates on the main thread right after the tab tap, within 2 to 20 cycles. Top frames: private `DesignLibrary` (no symbols), `SwiftUICore` `MaterialProviderBox.resolveLayers(in:)`, `GlassEffectResolvedMaterial.value.getter`, an `Attribute.init` closure, AttributeGraph update, `ViewGraph.updateOutputsAsync(at:)`. Exception type `EXC_BREAKPOINT (SIGTRAP)`.

Notes: replacing `.glassEffect` with `.background(.regularMaterial, in: .rect(cornerRadius: 24))` removes the crash in 2 of 2 runs; a no-sheet tab-switch cycle does not crash; one glass card on a tab was enough in the host app; the sheet's own content does not matter (a sheet with only a Cancel button reproduces). In the minimal project 1 of 2 completed glass runs crashed (cycle 7). Not tested on a device.

Environment: Xcode 27.2 (27B52), iOS 27.2 simulator runtime (24B8117), iPhone 17 simulator, host macOS 27.2.1.

## Baseline results

(Intentionally empty. No baseline was measured; see the close-out section below.)

## Owner decision C — close-out without device session (2026-11-13)

Appended after the round-2 results commit `6b0b063`. No earlier section was edited. The thresholds, the Route S / Route D decision rule, the threshold basis, and the data-dependence criteria in "Pre-registered decision rule" are unchanged and were never applied to data.

### Owner decisions this session (verbatim, with dates)

| Date | Decision | Verbatim | Effect |
|---|---|---|---|
| 2026-11-13 | B | "crash first" (recorded in the section "Crash isolation (owner decision B, 2026-11-13)" as "B: crash first") | Frame-delta measurement paused; crash on HEAD isolated first. |
| 2026-11-13 | C (round 2) | "bisect round 2 only" (recorded in the section "Crash isolation round 2" as "C only") | One more simulator bisect round plus a standalone minimal repro, then stop for a decision. |
| 2026-11-13 | C (no device) | "C: bez urządzenia" (Polish: "C: without the device") | Device session skipped; plan 09-07 is re-planned on simulator evidence. |

### Decision C006 acceptance statement

By choosing "C: bez urządzenia" the owner explicitly accepts that the reproducible simulator Liquid Glass resolution crash (`EXC_BREAKPOINT`, private `DesignLibrary`, `MaterialProviderBox.resolveLayers(in:)`, `GlassEffectResolvedMaterial.value.getter`) counts as the measured defect that decision C006 requires before any Liquid Glass change. This replaces the measured owner-reported flicker as the C006 evidence for plan 09-07. It is a simulator defect: the device flicker is not shown to be the same defect.

### Plan steps not executed, and why

| Plan step | Status | Reason |
|---|---|---|
| Task 1 step 5: HEAD frame-delta baseline (V0) and control baseline, Baseline results, Route line | Not executed | Impossible as written: HEAD crashes at cycle 2 or 3 in the sheet cycle (shake-down finding), so 20 sheet landings cannot be collected. Then paused by owner decision B. |
| Commit H (hypotheses H1 to H5 and the classification table, committed before any variant data) | Never written | The frame-delta variants it predicted were never measured. The crash-isolation hypotheses (CH1 to CH6, RH1 to RH6) were pre-registered in their own commits instead (`df74b25`, `0cdb397`), each before its runs. |
| Task 2: three diagnostic variants measured with the frame-delta rule, "Variant simulator results" with excursion counts | Not executed as written | The variants V1, V3, V4 were built and run, but as crash-isolation probes (crash or no crash), not frame-delta measurements; no excursion counts exist. Skipped by owner decision B. |
| Task 3: owner device session (six configurations, counts out of 6) | Skipped by owner decision | "C: bez urządzenia". Plan 09-07 does not request the session again unless the re-plan says so. |
| Task 2: `docs/DEVLOG.md` entry | Done in this close-out, with the content changed | See the DEVLOG entry of 2026-11-13. |

Executed and committed: harness and pre-registered rule (`010a843`), shake-down crash finding (`83fe65a`), crash isolation round 1 (`df74b25`, `dfb45e3`), crash isolation round 2 (`0cdb397`, `6b0b063`). Production source on the working branch was not changed in this plan.

### What remains open

- CH6 (simulator-only): not settled. The owner's device reports flicker and no crash.
- The flicker-to-crash link is not established. They share the Add Drink then Cancel then tab-switch cycle and the `glassEffect` material path; that is a lead, not a link.
- Crash rate per variant is unmeasured (one run each; the minimal repro crashed in 1 of 2 completed glass runs).
- Which property of a single glass card triggers the crash is not narrowed.

### Evidence for plan 09-07 to consume

- Round 1 table "Crash isolation results" (HEAD, V1, V3 crash; V4 material completes 20 of 20; the no-sheet control completes 20 of 20; CH3 supported, CH1, CH4, CH5 falsified, CH6 open).
- Round 2 tables under "Crash isolation round 2 results": stage 1 and stage 2 results (`DashboardHeroCard` on Home and `InsightsScopeNavigator` on Insights each suffice), the RH1 to RH6 verdicts (RH3 and RH5 supported), and the narrowest responsible view reading.
- The standalone minimal repro at `/Users/fempter/Developer/drinkpulse-diag/minimal-repro` (outside the repository, no app data): MR1 glass crashed in 1 of 2 completed runs with the same signature, the material control completed 20 of 20 in 2 of 2 runs.
- The draft Apple Feedback text in "Draft Feedback text (not submitted)". It was not submitted; whether to submit it is the owner's decision.
- Diagnostic worktrees and branches (`v1`, `v3`, `v4`, `work`, the `diag/09-crash-r2-*` branches, `minimal-repro`) are left in place; plan 09-09 handles cleanup. Crash reports are under `/Users/fempter/Developer/drinkpulse-diag/crash-reports/` outside the repository.

## Hypotheses and predictions (H1 to H5, transcribed in plan 09-07, 2026-11-13)

Transcription, not new pre-registration. Plan 09-06 Task 2 step 2 required this table to be committed to this file as "commit H" before any variant data. Commit H was never written (see "Plan steps not executed, and why"). The H1 to H5 predictions below are copied without change from the action text of `09-06-PLAN.md`, which was committed before any measurement existed (last revision `727a16d`, 2026-11-13 10:39; the harness commit `010a843` is 15:08). Nothing is added, reworded, or re-thresholded. Per-hypothesis outcomes are the classification of an owner-device or harness frame-delta observation as PRESENT or ABSENT under the pre-registered rule; a hypothesis is supported only when every one of its predictions holds.

| ID | Hypothesis | Predictions (PRESENT or ABSENT of the flash) |
|---|---|---|
| H1 | Sheet presentation over the TabView leaves tab content in a transient composite state | no-sheet control ABSENT, HEAD Debug PRESENT, trivial-sheet variant PRESENT, Release PRESENT |
| H2 | The Add Drink sheet content (its own glass tiles and form state) causes it | no-sheet control ABSENT, HEAD PRESENT, trivial-sheet variant ABSENT |
| H3 | Glass compositing (`glassEffect` backdrop re-sampling) carries it | no-sheet control ABSENT, HEAD PRESENT, material variant ABSENT |
| H4 | It is a Debug-build artifact | HEAD Debug PRESENT, Release ABSENT |
| H5 | The Dashboard container from commit 553ea58 is involved | no-container variant differs from HEAD on Dashboard only and not on Insights, which has no container (so H5 alone cannot explain the Insights flicker) |

Classification labels (plan 09-07 Task 1 step 2): C-DEBUG (H4 supported), C-SHEET (H1), C-CONTENT (H2), C-GLASS (H3), C-CONTAINER (H5), C-INCONCLUSIVE (no hypothesis fully supported, an AMBIGUOUS row decides the outcome, or the owner skipped the device session).

## Conclusion (plan 09-07, 2026-11-13)

This section applies only the rules, predictions, and criteria recorded above. No threshold, prediction, or criterion is added or changed after seeing the evidence, and no value is invented for an input that was never measured.

### Inputs that exist and inputs that are missing

| Input the plan 09-07 steps expect | State | Why |
|---|---|---|
| HEAD frame-delta baseline, control thresholds T_ctrl, and the Route S or Route D line | Missing | HEAD crashes at cycle 2 or 3 of the sheet cycle, so 20 sheet landings were never collected (shake-down finding); then paused by owner decision B. The pre-registered rule was never applied to any data. |
| Variant frame-delta excursion counts (trivial-sheet, material, no-container) | Missing | The variants were built and run only as crash probes (crash or no crash); owner decision B skipped the frame-delta measurement. |
| Owner device table (six configurations, counts out of 6) | Missing | Skipped by owner decision "C: bez urządzenia" (Polish; "C: without the device"). |
| Release-configuration run (needed by H1 and H4) | Missing | Never run; every run in this phase was a Debug build. |
| Crash isolation: HEAD, V1, V3, V4, six round-2 variants, minimal repro with control | Present | Round 1 and round 2 result tables above. Simulator evidence only (iPhone 17, iOS 27.2). |

Route: not determined. The Route S or Route D rule was never applied because the baseline it needs does not exist. For plan 09-07 the owner's close-out direction is to use Route D semantics: no automated flash regression exists on HEAD, and owner device confirmation is the only proof of any flicker fix.

### 1. Verdict table

All five hypotheses are stated in terms of flash PRESENT or ABSENT under the pre-registered rule, from the harness frame deltas or the owner device session. Neither observation exists, so no prediction of any hypothesis could be checked. A hypothesis is supported only when every prediction holds; with no observed prediction the verdict is untested, not refuted. The last column is context from the separately pre-registered crash hypotheses (CH1 to CH6, RH1 to RH6). It is not a verdict on H1 to H5, because a crash is not the flash the predictions describe.

| ID | Predictions | Simulator frame-delta result | Owner device result | Verdict | Crash evidence for context (not a verdict) |
|---|---|---|---|---|---|
| H1 | control ABSENT, HEAD Debug PRESENT, trivial-sheet PRESENT, Release PRESENT | none measured | no device data | untested | The crash needs the sheet cycle (no-sheet control 20 of 20 clean) and survives a trivial sheet (V3 crashed at cycle 2), but a sheet cycle with material instead of glass is clean (V4, 20 of 20), so the sheet cycle alone is not sufficient for the crash (CH4 falsified). |
| H2 | control ABSENT, HEAD PRESENT, trivial-sheet ABSENT | none measured | no device data | untested | V3 (trivial sheet) still crashes, so the Add Drink sheet content is not needed for the crash (CH2 falsified). |
| H3 | control ABSENT, HEAD PRESENT, material variant ABSENT | none measured | no device data | untested | Glass in tab content plus a sheet cycle is sufficient for the crash and the material variant is clean (CH3 supported, RH3 supported). |
| H4 | HEAD Debug PRESENT, Release ABSENT | none measured | no device data | untested | No Release run exists, so a Debug-only artifact is neither supported nor refuted for the crash or the flicker. |
| H5 | no-container variant differs from HEAD on Dashboard only | none measured | no device data | untested | V1 (no container) crashes like HEAD, and Insights has no container yet one glass card there also suffices (CH1 falsified, RH1 and RH2 falsified). |

### 2. Classification

Classification: C-INCONCLUSIVE.

- Reason 1: no hypothesis is fully supported (all five are untested).
- Reason 2: the owner skipped the device session, and the plan rule says that case is C-INCONCLUSIVE. The device session must be requested again before any claim about the flicker is made.

The narrowest responsible layer for the flicker is therefore not assigned. The label rules ask for evidence rows for a named layer, and none exist for the flicker.

Separate observation about the simulator crash (the defect the owner accepted for decision C006), recorded as a layer observation and not as a classification label, because the flicker-to-crash link is not established:

- Where it sits: in `glassEffect` material resolution (`MaterialProviderBox.resolveLayers(in:)`, `GlassEffectResolvedMaterial.value.getter`) at the first update after a tab switch lands on a tab that contains a live glass card, after an Add Drink then Cancel sheet cycle. This is the layer that label C-GLASS names (the shared `dpGlassCard` modifier in `DPGlass.swift`), reached through any single call site. Evidence rows: round 1 table (HEAD, V1, V3 crash; V4 material 20 of 20), round 2 stage 1 and stage 2 table (`DashboardHeroCard` alone on Home and `InsightsScopeNavigator` alone on Insights each crash), RH3 and RH5 supported, and the minimal repro (one glass card layout with no app data crashed in 1 of 2 completed runs; the material control was clean in 2 of 2).
- Ruled out as required for the crash, on simulator evidence: the Dashboard `GlassEffectContainer` (V1 crashes), the Add Drink sheet content (V3 crashes), the sheet presentation alone (V4 is clean with the same cycle), app data (the minimal repro has none), card variety (one card suffices).
- Not established: which property of one glass card triggers it, the per-variant crash rate (one run each), whether it also happens on a device (CH6, open), and whether a Release build crashes.

### 3. Data-dependence check

Data dependence: not shown (criterion 1 fails: the narrowest layer observed for the crash is `glassEffect` material resolution, not view content fed from the store, and the standalone minimal repro with static Text cards, no SwiftData, and no app data reproduces the crash; the seeded-store and empty-store shake-down runs both crashed in the sheet cycle; criterion 2 cannot apply: it needs a Route S owner device classification and a multiday baseline excursion count, and neither exists)

Limit of this finding: it covers the simulator crash only. For the owner-reported flicker, data dependence cannot be judged because no device data exists. `DashboardView.swift` does run a store load when the tab appears (`@Query` plus `onChange(of: allEvents, initial: true)`), and that is why the empty-data assumption flagged in the planning provenance stays open for the flicker. Because data dependence is not shown, the held-back empty-store harness test was not run and no empty-store measurement was recorded.

### 4. Proposed fix

Cure proposed: no (C-INCONCLUSIVE)

Under that line the plan rule offers no cure, only restoring `DashboardView.swift` and the option to gather more evidence. Independent of that rule, no cure can be designed from the recorded evidence:

- The trigger property of a single glass card is not narrowed, and the Apple documentation consulted for this phase (`glassEffect(_:in:)`, `GlassEffectContainer`, `Glass`, `sheet(isPresented:onDismiss:content:)`, `TabView`, `Tab`; re-checked 2026-11-13 through Xcode MCP `DocumentationSearch`) states no cause, no trap, and no interaction between a sheet and glass in tab content. A cure with no documented basis would be a guess.
- The only variant that removes the crash replaces glass with a regular material. The plan rule calls that a diagnostic result, not a proposal, and the project prohibition forbids replacing the centralized Liquid Glass layer as a workaround.
- The crash is intermittent (1 to 7 landings completed in the app variants before the crash; 1 of 2 completed glass runs crashed in the minimal repro), so a clean run cannot show a candidate cure works, and under Route D there is no frame-delta measurement to gate one. Plan 09-07 expects no builds, and none were made.

Cure diff: none (no cure proposed; no `diag/09-flash-v6-cure` branch or worktree was created)

Size review trigger: not tripped (0 changed lines, 0 files). This is the planner-set convention of 15 changed lines or 2 production files, used as a review flag and not a limit. For information only: commit `553ea58` changed 24 lines in one file (`DashboardView.swift`), and the only evidence-supported source change, restoring that file to its form before `553ea58`, is of that size. It is a revert, not a cure.

553ea58 container: it is not part of any evidenced cure. V1 (container removed) crashes as HEAD does, HEAD (container present) crashes at cycle 2 to 3, and the owner reported the flicker persisted after the container was added (DEVLOG 2026-09-18 21:15). Owner decision D1 replaces the container unless the diagnosis shows it is part of the right fix, and the diagnosis does not. Restoring `DashboardView.swift` to the `553ea58^` form is therefore the only source change this evidence supports, and it does not remove the crash or the flicker.

### 5. What stays open

- Whether the device flicker is the crash path failing softly, or an unrelated device-only symptom (CH6 and the flicker-to-crash link).
- Every H1 to H5 prediction, which needs the owner device session to be requested again (and a Release run for H1 and H4).
- The empty-data assumption for the flicker (see the data-dependence limit above); adjacency and ordering also stay open and carry to the plan 09-10 owner checklist.
- The submission of the draft Apple Feedback text is the owner's call.
- `SheetDismissTabSwitchUITests` is committed on HEAD, has no skip entry in the shared scheme (`drinkpulse.xcscheme`, no test plan exists), and its sheet-mode test crashes the app on HEAD within 2 to 3 cycles. Any full UI suite run before this is resolved can fail on it. It is a harness-versus-defect interaction for the plans after 09-07 to decide, not a change made here.

## Owner decision on the fix (plan 09-07 Task 2, 2026-11-13)

Appended after the Conclusion and the C013 brief draft (`08-DECISION-C013.md`, outcome pending). No earlier section was edited. The brief and the decision register are unchanged here; plan 09-08 records the outcome in them.

Date of the owner reply: 2026-11-13.

Original language of the reply: Polish, given through a structured choice. The recommendation in the question was the executor's and was explicitly not an approval.

**Owner response (English translation).** Question asked: "C013: which option do you choose? The executor recommends revert-container-only (this is not an approval), with the caveat that the on-device session and the Feedback decision stay open. I will record your answer verbatim. If you want to add a scope change, write it in the note." Selected option: "revert-container-only". Option text the owner selected: "Restores DashboardView.swift to before 553ea58 (removes the unauthorized GlassEffectContainer). Does not fix the crash or the flicker; MOD-02 stays open. Selecting it = acknowledging the line "Automated flash regression: none (Route D) — owner device confirmation is the only proof". The device session and Feedback stay open." No additional scope note was given.

**Owner response (Polish original).** Pytanie: "C013: którą opcję wybierasz? Executor rekomenduje revert-container-only (to nie jest zatwierdzenie), z zastrzeżeniem, że sesja na urządzeniu i decyzja o Feedback zostają otwarte. Twoją odpowiedź zapiszę dosłownie. Jeśli chcesz dodać zmianę zakresu, wpisz ją w notatce." Wybrana opcja: "revert-container-only". Tekst wybranej opcji: "Przywraca DashboardView.swift sprzed 553ea58 (usuwa nieautoryzowany GlassEffectContainer). Nie naprawia crasha ani flickera; MOD-02 zostaje otwarte. Wybór = potwierdzenie linii: "Automated flash regression: none (Route D) — owner device confirmation is the only proof". Sesja na urządzeniu i Feedback zostają otwarte."

Chosen option: revert-container-only

Automated flash regression acknowledged: none (Route D) — owner device confirmation is the only proof

Scope amendment: none beyond the option text. The on-device session and the decision on submitting the draft Apple Feedback text stay open. The decision does not fix the simulator crash or the device flicker, and MOD-02 stays open.

Size review trigger decision: not applicable. The brief says `Size review trigger: not tripped (0 changed lines, 0 files)` because no cure is proposed; apply-proposed-fix was not offered.

What this decision authorizes: plan 09-08 restores `drinkpulse/Features/Dashboard/DashboardView.swift` to its form before commit `553ea58`, and nothing else in production source. What it does not authorize: any change to `DPGlass.swift` or any `glassEffect` consumer, any cure, any claim that the flicker or the crash is fixed, closing the pending todo, or marking MOD-02 complete.

## Owner decisions after 09-08 scoped UI gate (2026-11-13)

Appended after plan 09-08 stopped at its scoped-suite gate (47 of 51 passed; failures: two `HistoryInteractionUITests` edit tests and the two crashing `SheetDismissTabSwitchUITests` tests). No earlier section was edited.

**Decision 1: harness crash.**
- Polish original (verbatim): "Najpierw napraw crash"
- English translation: "Fix the crash first."
- Effect: plan 09-08 waits for a crash workaround. The workaround must NOT replace glass with material (the prohibition on replacing the centralized Liquid Glass layer stands). No skip entry, quarantine, or `XCTExpectFailure` is added for the harness tests.

**Decision 2: History edit tests.**
- Polish original (verbatim): "Osobny defekt, waiver (Rekomendowane)"
- English translation: "Separate defect, waiver (Recommended)."
- Effect: `HistoryInteractionUITests/test_editCustomNameAndNotes_persist` and `HistoryInteractionUITests/test_editCategoryChange_persists` are recorded as a separate pre-existing defect (pending todo `.planning/todos/pending/2026-11-13-history-edit-uitests-failing.md`) and are waived by name for the plan 09-08 gate only. Diagnosis and fix happen separately (for example `/gsd-debug`).
