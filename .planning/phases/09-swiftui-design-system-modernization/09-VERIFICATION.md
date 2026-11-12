---
phase: 09-swiftui-design-system-modernization
verified: 2026-11-12T21:55:00+01:00
status: gaps_found
score: 12/14 must-haves verified
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/phases/09-swiftui-design-system-modernization/09-01-PLAN.md
  - .planning/phases/09-swiftui-design-system-modernization/09-01-SUMMARY.md
  - .planning/phases/09-swiftui-design-system-modernization/09-02-PLAN.md
  - .planning/phases/09-swiftui-design-system-modernization/09-02-SUMMARY.md
  - .planning/phases/09-swiftui-design-system-modernization/09-03-PLAN.md
  - .planning/phases/09-swiftui-design-system-modernization/09-03-SUMMARY.md
  - .planning/phases/09-swiftui-design-system-modernization/09-ADD-DRINK-EVIDENCE.md
  - .planning/phases/09-swiftui-design-system-modernization/09-DASHBOARD-EVIDENCE.md
  - .planning/phases/09-swiftui-design-system-modernization/09-RETAIN-EVIDENCE.md
  - .planning/phases/09-swiftui-design-system-modernization/09-REVIEW.md
  - .planning/phases/09-swiftui-design-system-modernization/09-UAT.md
  - drinkpulse/DesignSystem/DPArcProgress.swift
  - drinkpulse/DesignSystem/DPGlass.swift
  - drinkpulse/Domain/GuidelineLimits.swift
  - drinkpulse/Features/AddDrink/AddDrinkView.swift
  - drinkpulse/Features/AddDrink/DrinkDetailInputView.swift
  - drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift
  - drinkpulse/Features/AddDrink/DrinkTypeGridView.swift
  - drinkpulse/Features/Dashboard/DashboardView.swift
  - drinkpulse/Features/History/Components/HistoryCalendarDayDetail.swift
  - drinkpulse/Features/History/HistoryListQueryView.swift
  - drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift
  - drinkpulse/Features/Shell/RootShellView.swift
  - drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift
  - drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift
covered_digest: "v4:sha256:a7365bfcf5903ceca8755d9cb377a704532a4379a98cbc3fe7f1465e7e9517e6"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 7/7 must-haves verified
  previous_verified: 2026-09-19T08:30:00+02:00
  reason: "Previous report went stale because .planning/REQUIREMENTS.md changed in 8445073. The previous report had no gaps: section, so this pass uses initial-mode must-have derivation (Step 0). The new-scope evidence gate (#3304) therefore did not apply."
  gaps_closed: []
  gaps_remaining: []
  regressions: []
  coverage_corrections:
    - "Previous covered set omitted drinkpulse/Features/Dashboard/DashboardView.swift (commit 553ea58, 2026-09-18) and drinkpulse/Domain/GuidelineLimits.swift (commit 7bf6b2a). Both are now covered and both produce findings below."
    - "Prior report stated the Dashboard flash was not expanded into this phase. Commit 553ea58 expanded it."
gaps:
  - truth: "Phase goal and Plan 03 truth 6: interface code is updated only where Phase 08 found a documented, behaviorally appropriate replacement, and centralized Liquid Glass remains unchanged unless measured visual, contrast, accessibility, or context-menu evidence supports a local correction"
    status: failed
    reason: "DashboardView.swift wraps its card stack in GlassEffectContainer(spacing: 0) (commit 553ea58, 2026-09-18 21:14, subject 'fix(09): contain dashboard glass effects'). No Phase 08 candidate authorizes it: UI-C-09 is Retain, and decision C006 permits Liquid Glass changes only for a specifically measured defect. No Phase 09 plan, summary, or 09-RETAIN-EVIDENCE.md entry records the change. Its own DEVLOG entry (docs/DEVLOG.md, 2026-09-18 21:15) says the flash cannot be claimed as independently reproduced and awaits owner visual confirmation. The pending todo .planning/todos/pending/2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md says the flash persists after the change and that the owner deferred it. 09-ADD-DRINK-EVIDENCE.md says the flash would be diagnosed before any source change. The decision register (08-DECISION-REGISTER.md) requires a new brief and register row before an unplanned rewrite."
    artifacts:
      - path: "drinkpulse/Features/Dashboard/DashboardView.swift"
        issue: "Line 14 wraps the Dashboard card stack in GlassEffectContainer(spacing: 0). Unplanned Liquid Glass composition change with no documented replacement, no reproduced defect, and no retain-record entry. The Dashboard UI tests pass, so this is a scope and evidence gap, not a test failure."
    missing:
      - "Choose one: (a) revert DashboardView.swift to its pre-553ea58 layout, which restores the Phase 08 retain baseline; or (b) add a new source-backed decision brief and an independent row in 08-DECISION-REGISTER.md, record the change under UI-C-09 in 09-RETAIN-EVIDENCE.md, and obtain owner on-device visual confirmation that the flash is resolved."
      - "Correct the stale 09-VERIFICATION.md Gaps Summary line that says the Dashboard flash was not expanded into this phase."
deferred: []
behavior_unverified_items: []
coincidental_reliance_items: []
---

# Phase 09: SwiftUI & Design System Modernization Verification Report

**Phase Goal:** Update interface code where Phase 08 finds a documented, behaviorally appropriate replacement.
**Verified:** 2026-11-12T21:55:00+01:00
**Status:** gaps_found
**Re-verification:** Yes, after the prior report went stale. Initial-mode derivation applied because the prior report had no `gaps:` section.

## Verdict

The phase goal is NOT achieved as written. The three documented changes are present and wired: UI-C-02 (DPArcProgress nonisolated repair), UI-C-01 (Add Drink DismissAction ownership), and UI-C-10 (one Xcode 27 VoiceOver regression). Retained surfaces (UI-C-03 through UI-C-09) are present and unchanged at the points the record names. However, commit 553ea58 changed Liquid Glass composition on the Dashboard with no Phase 08 authorization and no reproduced defect. The change is not recorded in any Phase 09 artifact, and its own pending todo says the target defect persists. That is one BLOCKER.

Score: 12 of 14 must-have truths VERIFIED. One is FAILED (BLOCKER). One is UNCERTAIN (WARNING). MOD-02 is accounted for.

Automated tests were not re-executed in this pass. XCUITests need a simulator build and exceed the Step 7b spot-check budget. Test-pass claims below rest on the recorded runs in the SUMMARY and evidence files, the test files' existence in source, and the owner UAT of 2026-11-10 (09-UAT.md, 6 of 6 pass).

## Must-Have Truths

| # | Plan | Truth | Status | Evidence |
| --- | --- | --- | --- | --- |
| 1 | 09-01 | Arc compiles under iOS 27 Debug and Release without changing sweep geometry, value animation, or accessibility label | VERIFIED | `git show 7bf6b2a` changes only `private struct ArcShape` to `nonisolated private struct ArcShape` in DPArcProgress.swift. Geometry (startDeg 60, sweepDeg 240, `addArc`), `.animation(hasSettledOnce ? ... : nil, value: pct)`, and `arcLabel` are unchanged. Debug and Release build results are recorded in 09-DASHBOARD-EVIDENCE.md (not re-run here). |
| 2 | 09-01 | Seeded Dashboard flow still renders the hero value, proved by a focused XCUITest | VERIFIED | `DashboardUITests.swift:22` `test_heroCard_showsSeededConsumptionValue` asserts the "Today's Intake" label. `DashboardHeroCard.swift:52` renders `DPArcProgress(pct: vm.todayPct, ...)`. Recorded run: 5/5 pass (Xcode MCP, 09-DASHBOARD-EVIDENCE.md). Not re-executed. |
| 3 | 09-01 | Human VoiceOver and visual inspection recorded with toolchain, simulator, and outcome | VERIFIED | 09-DASHBOARD-EVIDENCE.md "Human check: pass" with Xcode 27.0 / iOS 27.0 / iPhone 18 Pro. UAT item 1 pass. |
| 4 | 09-02 | Cancel and successful save close the sheet to the originating tab; save still persists | VERIFIED | `AddDrinkFlowUITests.swift` `test_originatingHistoryTab_gridCancel_returnsToHistory` covers grid Cancel from History. `test_originatingSettingsTab_save_persistsAndReturnsToSettings` covers save from Settings, including History persistence. UAT item 2 pass, including persistence after relaunch. Detail-form Cancel has no automated test; it is owner-verified only (09-ADD-DRINK-EVIDENCE.md). |
| 5 | 09-02 | Sheet-root DismissAction is read at the sheet root and propagated through the existing route | VERIFIED | `AddDrinkView.swift:4-9` reads `@Environment(\.dismiss) private var dismissSheet` outside the NavigationStack and passes it to `DrinkTypeGridView(dismissSheet:)`. `DrinkTypeGridView.swift:4,13,17` passes it to `DrinkDetailInputView(preset:dismissSheet:)`. `DrinkDetailInputView.swift:6,23-25,119` stores it and uses it for Cancel. `DrinkDetailInputView+Logic.swift:73` calls it after insert, dedupe, and HealthWriteHooks. The old `\.dismissSheet` environment key has no remaining references. |
| 6 | 09-02 | Cancel is reachable by its semantic label, and one durable Xcode 27 VoiceOver regression exercises the meaningful dismissal flow | UNCERTAIN (WARNING) | Semantic reachability holds: `ShellNavigationUITests.swift` queries `navigationBars["Add Drink"].buttons["Cancel"]`. The VoiceOver test (lines 101-137) asserts that VoiceOver announces "Cancel" within 40 swipes. It then calls `voiceOver.disable()` at line 132 before `cancel.tap()`, so the dismissal itself is not performed under VoiceOver. The test has no XCTSkip guard when `voiceOverService` is unavailable, and its name `test_voiceOver_cancelDismissesAddDrinkAndReturnsToHistory` overstates what it proves. Owner UAT item 3 (pass) covers VoiceOver-activated Cancel manually. Decision requested (see below). |
| 7 | 09-02 | Add Drink visual and accessibility verification documented separately from automated results | VERIFIED | 09-ADD-DRINK-EVIDENCE.md has a separate "Human check" section. UAT items 2 and 3 pass. |
| 8 | 09-03 | Candidate index has a change or retain disposition for UI-C-01 through UI-C-10 | VERIFIED | 09-RETAIN-EVIDENCE.md table: UI-C-01, UI-C-02, UI-C-10 are Change (tied to Plans 01 and 02); UI-C-03 through UI-C-09 are Retain. Matches 08-INVENTORY-UI.md rows and owner-approved register entries C001 to C012. Caveat: the index omits the Dashboard change in gap 1. |
| 9 | 09-03 | UI-C-03: stable ForEach identity; History event rows keep `uuid` identity | VERIFIED | `HistoryCalendarDayDetail.swift:57` `ForEach(events, id: \.uuid)`. `HistoryListQueryView.swift:40` `ForEach(rows)`. `HistoryCalendarView.swift:67,73` `ForEach(weekdayLabels)` and `ForEach(cells)`. No positional identity introduced. History files have no Phase 09 commits. |
| 10 | 09-03 | UI-C-07: `@Observable @MainActor` models with `@State` owners; Insights cache uses `@ObservationIgnored` | VERIFIED | `DashboardViewModel.swift:12`, `HistoryViewModel.swift:18`, `InsightsViewModel.swift:3`, `OnboardingViewModel.swift:4` are `@Observable @MainActor final class`. Owners: `DashboardView.swift:5`, `HistoryView.swift:20`, `InsightsView.swift:5`, `OnboardingView.swift:7` use `@State private var vm`. `InsightsViewModel.swift:17,158,159` use `@ObservationIgnored`. |
| 11 | 09-03 | History stays a native List with calendar branch, paging, context-menu actions, and destructive confirmation | VERIFIED | `HistoryListQueryView.swift:39` `List {`. `EventContextMenu.swift` and History list and calendar code have no Phase 09 changes (git history). Focused suites recorded in 09-RETAIN-EVIDENCE.md. UAT item 4 pass. |
| 12 | 09-03 | Insights retains chart selection, callouts, labels, both Audio Graph descriptor paths, and no-callout-slide under Reduce Motion | VERIFIED | `AlcoholAreaChart.swift:64` `chartXSelection`, `:79` `accessibilityChartDescriptor`, `:96-105` Reduce Motion gate on callout transition and animation. `WeekdayBarChart.swift:10,41,55` has the same pattern. `AlcoholAreaChart+Accessibility.swift` and `WeekdayBarChart+Accessibility.swift` exist. UAT item 4 pass (Reduce Motion discrete in both modes). |
| 13 | 09-03 | Centralized Liquid Glass remains unchanged unless measured evidence supports a local correction | FAILED (BLOCKER) | `DPGlass.swift` is unchanged (last commit 6d12cb1, 2026-08-17). However, `DashboardView.swift:14` wraps the card stack in `GlassEffectContainer(spacing: 0)` (commit 553ea58). No measured defect was reproduced: docs/DEVLOG.md 2026-09-18 21:15 says the flash cannot be claimed as independently reproduced. The change is absent from the retain record. See gap 1. |
| 14 | 09-03 | Each retained workaround has a durable record with path, iOS 27 evidence, protected behavior, and rationale; the disabled spec-less probe fallback is visible | VERIFIED | 09-RETAIN-EVIDENCE.md has one row per candidate and per-candidate rationale. Its environment table records "spec-less probe fallback: disabled by project configuration". Caveat: the record omits the Dashboard change (gap 1). |

**Score:** 12/14 truths verified. 1 UNCERTAIN (WARNING, truth 6). 1 FAILED (BLOCKER, truth 13).

Phase-goal check: the phase goal is not met while the Dashboard glass change stands (gap 1). Plan-level changes outside the phase goal are recorded under warnings below.

## Roadmap Success Criteria

| # | Criterion | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Every Phase 08 candidate has a documented disposition with evidence; substantial rewrites have an owner-discussed brief | VERIFIED (caveat) | Dispositions present in 09-RETAIN-EVIDENCE.md. Owner approvals C001 to C012 are in 08-DECISION-REGISTER.md. Caveat: the unplanned Dashboard change has no brief or register row (gap 1). |
| 2 | Navigation, tabs, sheets, forms, History, and Insights work on iOS 27 in affected flows | VERIFIED | Recorded focused runs (49 selected tests; 6/6 AddDrink; 4/4 ShellNavigation; 5/5 Dashboard). UAT items 1 to 4 pass on 2026-11-10. Not re-executed here. |
| 3 | Chart and History workarounds are retained unless iOS 27 reproduction and a verified replacement justify removal | VERIFIED | No commit in the Phase 09 window touches History or Insights source. List, calendar, and chart descriptor code is present (see truths 9 to 12). |
| 4 | Affected accessibility, localization, and Reduce Motion behavior verified by tests or explicit human checks | VERIFIED (caveat) | VoiceOver and Reduce Motion are covered by UAT items 1, 3, and 4. Caveat: the arc accessibility label `"\(pctInt)% of daily limit"` is not localized and the arc animation does not honor Reduce Motion (pre-existing; see advisory items). |

## Requirements Coverage

| Requirement | Claimed by | Status | Evidence |
| --- | --- | --- | --- |
| MOD-02 | 09-01, 09-02, 09-03 frontmatter (`requirements: [MOD-02]`) | SATISFIED on requirement text | REQUIREMENTS.md:18 requires users to retain navigation, forms, sheets, History, and Insights behavior, and removal of workarounds only after iOS 27 evidence. Retained-behavior evidence exists (recorded runs and UAT). The Dashboard change does not affect the listed surfaces. |

Bookkeeping: REQUIREMENTS.md still shows MOD-02 as `[ ]` with "Pending" in the traceability table (lines 18 and 56). Flip both after gap 1 is closed. No orphaned requirement IDs exist for Phase 09; REQUIREMENTS.md maps only MOD-02 to Phase 09.

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| RootShellView.swift | AddDrinkView.swift | `.sheet(isPresented: $showAddDrink) { AddDrinkView() }` | WIRED | `RootShellView.swift:80-82`. Commit 249de68 (Phase 10) edited this file, but not the sheet block. |
| AddDrinkView.swift | DrinkDetailInputView+Logic.swift | DismissAction propagated to save and cancel | WIRED (manual) | CLI reported false negative: the literal `DismissAction` is not in either named file. Manual trace: `AddDrinkView.swift:5` → `DrinkTypeGridView.swift:4,13` → `DrinkDetailInputView.swift:6,23-25` → `+Logic.swift:73`. |
| DashboardHeroCard.swift | DPArcProgress.swift | `DPArcProgress(pct: vm.todayPct, ...)` | WIRED | CLI verified; `DashboardHeroCard.swift:52`. |
| DashboardUITests.swift | DashboardHeroCard.swift | Seeded hero assertions | WIRED | CLI verified; "Today's Intake" in the test and in Localizable.xcstrings. |
| HistoryListQueryView.swift | HistoryInteractionUITests.swift | List coverage | WIRED | CLI verified; `HistoryListQueryView.swift:39` `List {`. |
| AlcoholAreaChart.swift | AlcoholAreaChart+Accessibility.swift | `accessibilityChartDescriptor` | WIRED | CLI verified. |
| DPGlass.swift | EventContextMenu.swift | Centralized glass and context menu evidence | WIRED (weak link) | CLI verified only against DPGlass.swift (`.glassEffect`). The link spec is loose; EventContextMenu is not itself a glass consumer. Informational. |
| DashboardView.swift | DashboardViewModel.swift | `@State private var vm` owner | WIRED | CLI verified; `DashboardView.swift:5`. |
| HistoryCalendarDayDetail.swift | HistoryListQueryView.swift | `ForEach(events, id: \.uuid)` | WIRED (manual) | CLI reported false negative: the pattern is in the `from` file, not the `to` file. Manual: `HistoryCalendarDayDetail.swift:57`. |

## Artifacts

| Artifact | Exists | Substantive | Wired | Data Flows | Status |
| --- | --- | --- | --- | --- | --- |
| DPArcProgress.swift | yes | yes | yes | N/A (existing data path unchanged) | VERIFIED |
| 09-DASHBOARD-EVIDENCE.md | yes | yes | n/a | n/a | VERIFIED |
| AddDrinkView.swift, DrinkTypeGridView.swift, DrinkDetailInputView.swift, DrinkDetailInputView+Logic.swift | yes | yes | yes | N/A (dismissal path) | VERIFIED |
| AddDrinkFlowUITests.swift, ShellNavigationUITests.swift | yes | yes | yes | n/a | VERIFIED (VoiceOver test caveat, truth 6) |
| 09-ADD-DRINK-EVIDENCE.md | yes | yes | n/a | n/a | VERIFIED |
| 09-RETAIN-EVIDENCE.md | yes | yes | n/a | n/a | VERIFIED as to UI-C-01 to UI-C-10; incomplete for the Dashboard change |
| DashboardView.swift | yes | yes | yes | N/A | FAILED (unplanned Liquid Glass change; gap 1) |
| GuidelineLimits.swift | yes | yes | yes | N/A | WARNING (unplanned Domain annotation; warning 2) |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Old `\.dismissSheet` environment key removed | `grep -rn '\.dismissSheet' drinkpulse` | No matches | PASS |
| `DismissAction` is propagated, not read in children | `grep -rn 'DismissAction' drinkpulse/Features/AddDrink` | Matches in DrinkTypeGridView.swift and DrinkDetailInputView.swift only | PASS |
| Plan 03 retain-only claim for files changed by Plan 03 | `git log --since=2026-09-19T08:30:00+02:00 -- <covered UI paths>` | Protected-path changes only in RootShellView.swift (249de68, Phase 10 weekly-summary routing, sheet block unchanged) and Phase 10 test files | PASS (no Phase 09 change after the prior verification) |
| XCUITest runs (AddDrink, Shell, Dashboard) | Not run | Simulator build exceeds the 10-second spot-check budget | SKIPPED (recorded evidence and owner UAT used) |

## Probe Execution

No probes declared or found (`scripts/*/tests/probe-*.sh` does not exist). Not applicable.

## Anti-Patterns and Code Review (09-REVIEW.md, 0 critical / 5 warning / 4 info, all open)

No TBD, FIXME, XXX, TODO, HACK, or PLACEHOLDER markers exist in the modified implementation files. No debt-marker gate triggered.

Code-review findings were triaged against the must-haves. None is a must-have failure except as noted:

| Finding | Severity | Pre-existing or phase-introduced | Disposition |
| --- | --- | --- | --- |
| WR-05 VoiceOver test does not exercise VoiceOver-activated dismissal | warning | Phase-introduced (09-02) | Contradicts truth 6 precision. Routed to WARNING, decision D2. |
| WR-01 Arc animation never interpolates (ArcShape has no `animatableData`) | warning | Pre-existing; preserved by Plan 01 | Advisory. Plan 01 required preserving the animation contract. |
| WR-02 Arc label hardcoded English; arc animation ignores Reduce Motion | warning | Pre-existing; preserved by Plan 01 | Advisory. Feeds roadmap SC4 caveat. |
| WR-03 Custom drink in imperial mode saves a volume absent from the picker | warning | Pre-existing (onAppear unchanged by Phase 09) | Advisory. Preserving existing behavior. |
| WR-04 `parsedPrice` accepts NaN, infinity, and negatives | warning | Pre-existing (Logic `parsedPrice` unchanged) | Advisory. |
| IN-01 Previews of DrinkDetailInputView show the grid, not the detail with mock data | info | Phase-introduced (09-02 changed previews) | Advisory. Dev tooling only; AGENTS.md preview rule. |
| IN-02 Save has no re-entry guard | info | Pre-existing | Advisory. |
| IN-03 ArcShape radius ignores stroke width | info | Pre-existing | Advisory. |
| IN-04 Weak UI test locators | info | Mixed | Advisory. |

## Human Verification and Decisions Requested

Status is gaps_found, so these are decisions, not blocking UAT items:

**D1 (gap 1, blocking).** Dashboard Liquid Glass change in `DashboardView.swift` (commit 553ea58). Revert it, or ratify it through a decision brief and register row, a 09-RETAIN-EVIDENCE.md update, and owner on-device confirmation that the flash is gone. The pending todo says the flash persists after the change.

**D2 (warning, truth 6).** VoiceOver regression in `ShellNavigationUITests.swift`. Either accept the current test and rely on UAT item 3 for VoiceOver-activated Cancel, or rewrite it to activate Cancel while VoiceOver is on, add an XCTSkip guard for unavailable `voiceOverService`, and rename it to match what it proves.

**D3 (warning 2).** `GuidelineLimits.swift` `nonisolated var effectiveDailyGrams` (commit 7bf6b2a). This is a compile-only annotation in the Domain layer, outside 09-01's files_modified and outside the Phase 08 candidate index. Either record it in 09-RETAIN-EVIDENCE.md or Phase 08's deviation log as an accepted test-target compile fix, or revert it if the test target compiles another way.

## Warnings (non-blocking)

1. VoiceOver test durability (truth 6, D2).
2. Undocumented Domain annotation `GuidelineLimits.swift` (D3). Behavior-neutral; documented only as a deviation in 09-01-SUMMARY.md.
3. Retain record omits the Dashboard change (gap 1). Recorded here because it blocks the UI-C-09 retain claim, not as a separate gap.

## Gaps Summary

One BLOCKER: the Dashboard Liquid Glass change in commit 553ea58 is an interface change with no Phase 08 replacement, no reproduced defect, and no record in the phase artifacts. It conflicts with the phase goal and with the retain record for UI-C-09. Its own todo says the target defect persists. Closing it requires either reverting `DashboardView.swift` or documenting a new decision brief, a register row, and owner visual confirmation. After closure, flip REQUIREMENTS.md MOD-02 to `[x]` and Complete.

Mode note: this pass uses initial-mode derivation (Step 0), so the Blocker is not subject to the re-verification evidence gate. Under a re-verification reading, `DashboardView.swift` predates the prior `verified:` timestamp and would need deterministic evidence to block. No such evidence exists, so the finding would fall to advisory. The gap-1 classification depends on this mode decision.

---

_Verified: 2026-11-12T21:55:00+01:00_
_Verifier: Claude (gsd-verifier)_
