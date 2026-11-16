# Phase 11: iOS 27 Release Verification - Context

**Gathered:** 2026-11-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 11 shows that the iOS 27 migration is warning-clean, data-safe and accessible, and records build and test evidence for it (MOD-04, VER-01, VER-02, VER-03). It resolves app-owned deprecation warnings without suppression. It records Debug and Release builds and the scoped and then full regression suites on iOS 27. It proves the core user flows, records the accessibility checks, reconciles the three skipped Phase 05 chart checks, and confirms that every substantial modernization discovery has a recorded outcome. It does not fix unrelated verification debt and must not silently close it.

</domain>

<decisions>
## Implementation Decisions

### Readiness of prior phases
- **D11-01:** Proceed without re-verifying Phases 08–10. Treat them as done, based on their closure plans: 08-08, 09-10 (closed with D1 deferred) and 10-14. Phase 11 does not re-run the phase verifier for 08, 09 or 10. The stale `09-VERIFICATION.md` (gaps_found, written before 09-10) and the "stale" status of 08 and 10 are listed in the Phase 11 debt ledger as known record states. They are not fixed or rewritten here.

### Regression suite scope (VER-01)
- **D11-02:** No test or app fixes in Phase 11 for the known non-green items. Each one is recorded as an open limitation with its cause, todo or open-question link, and owner. VER-01 passes with these named exceptions. The items are: `InsightsUITests.test_heroCard_holdsHeight_whenSwitchingToAllTimeScope` (pre-existing failure), the two `HistoryInteractionUITests` edit tests that fail when run alone (todo `2026-11-13-history-edit-uitests-failing.md`), the Export dismiss UI test flake (todo `2026-11-13-export-dismiss-uitest-flaky.md`), and the two D1 crash harness tests gated behind `DP_RUN_FLASH_HARNESS` (todo `2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md`). A new failure that is not on this list is a blocker. It is not added as a silent exception.

### Accessibility human checks (VER-03)
- **D11-03:** The owner runs the human accessibility checklist on the iOS 27 simulator, not on the iPhone. The checklist covers: VoiceOver on both chart Audio Graphs (AlcoholAreaChart and WeekdayBarChart), Reduce Motion, Dynamic Type through AX5, light and dark appearance, and Increase Contrast. Each item is recorded as passed, failed or explicitly open. The evidence states that the run was on a simulator, not a device. Automated results (XCUITest and accessibility audits) and human results are kept in separate columns.

### Core flow proof (VER-02)
- **D11-04:** Automated UI tests cover onboarding, startup/retry, add/edit/delete, History list and calendar, Insights, settings and backup export/import on iOS 27. The proof that existing data is preserved cites the Phase 10 device session (`10-DEVICE-SESSION.md`: in-place upgrade, import round trip, edit/delete, 214 events before and after). No new device session is planned. The evidence states a limitation: the device proof was made before the Phase 09-10 code changes, which reverted the Dashboard container and gated the harness tests.

### Toolchain and destination (owner update, 2026-11-14)
- **D11-05:** Phase 11 evidence uses the installed Xcode 27.2 (27B52) with the iOS 27.2 SDK (`iphoneos27.2` / `iphonesimulator27.2`), and the iPhone 18 Pro simulator on the iOS 27.2 runtime as the primary destination. The iPhone 18 Pro Max on iOS 27.2 is the secondary destination. This replaces the Phase 08 baseline toolchain (Xcode 27.0, 27A266a), so VER-01 evidence must record the toolchain change and must not reuse Phase 08 version strings. `IPHONEOS_DEPLOYMENT_TARGET` stays 27.0 in every target and configuration. The minimum OS is a product decision, and raising it is out of scope.

### Decided autonomously (and research/plan-check follow-ups)
- **D11-06:** [Warnings] Do clean Debug and Release builds, extract every warning from the logs, classify each one as app-owned or external, and fix app-owned warnings at the source. Any fix that changes behavior or data goes through the Phase 08 D-09 brief first. An external warning records its official source, impact and follow-up. (Question: How to find deprecation warnings (MOD-04)?; reversible: evidence method only; changing it later does not affect code.)
- **D11-07:** [Evidence] One 11-EVIDENCE.md with the exact commands, Xcode and Swift versions, SDK and runtime, destination, counts and log hashes. Raw logs stay outside git (Phase 08 D-13 pattern). (Question: Where does the evidence go?; reversible: document layout only.)
- **D11-08:** [Tooling] Xcode MCP first. The CLI xcodebuild is used only where the MCP test timeout is known to break long UI suites (Phase 09-03 precedent), and the evidence records which runner was used. Scoped runs come first, then the full suite. (Question: How are builds and tests run?; reversible: runner choice; the results are the same.)
- **D11-09:** [Phase 05 debt] Fold the Reduce Motion check and both Audio Graph checks into the VER-03 human checklist, each linked back to the archived 05-UAT.md tests 4, 5 and 6, and record the outcome against each one. (Question: How are the three skipped Phase 05 checks handled?; reversible: checklist mapping only.)
- **D11-10:** [Debt ledger] Add a ledger table that lists D1, WINDOWS.md row 7 (Domain coverage), the open-questions items, the pending todos and the prior-phase verification record states, each with its status and owner. Nothing is closed without evidence. (Question: How is the do-not-silently-close-debt criterion met?; reversible: record only.)
- **D11-11:** [Discoveries] Cross-check C001 to C013 and the Phase 10 decisions F2 to F4 and the device finding against their decision records, and confirm that each one has a recorded analysis and outcome. (Question: How is SC5 (modernization discoveries) checked?; reversible: read-only audit.)

- **D11-12:** [Research follow-up] Add one test-only class drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift using performAccessibilityAudit, with an allow-list that holds only issues recorded in the debt ledger. No production code changes. (Question: Add an automated accessibility audit test?; reversible: test-only file, deletable without side effects.)
- **D11-13:** [Research follow-up] Record it as a VER-02 limitation, backed by the existing importer unit tests and the Phase 10 device import round trip. No new UI test that drives the system picker (the simulator locale is Polish). (Question: Backup import has no UI test (system fileImporter picker). New test or limitation?; reversible: record only.)
- **D11-14:** [Research follow-up] All nine production files changed after a38a75f (git diff --stat a38a75f HEAD -- drinkpulse), named one by one, not only the Dashboard revert and the harness gating. (Question: Which files does the device-proof limitation list?; reversible: record only.)
- **D11-15:** [Research follow-up] Yes. Xcode MCP cannot collect coverage, which counts as a named missing capability, so one detached xcodebuild full run uses -enableCodeCoverage YES. Scoped runs stay on MCP. (Question: Is the full suite with coverage run through the CLI?; reversible: runner choice.)
- **D11-16:** [Research follow-up] Re-run it once alone. If it passes on the re-run, record it as a newly observed flake with a new todo. If it fails again, it is a blocker for the owner. (Question: What happens with a failure not on the known list?; reversible: evidence protocol.)
- **D11-17:** [Research follow-up] Put each one on the VER-03 human checklist. A confirmed defect gets an owner D-09 brief and stays open. Phase 11 makes no fix. (Question: Animations not gated by Reduce Motion (DPArcProgress.swift:18, ConsumptionOverviewCard.swift:110, HistoryCalendarView.swift:61)?; reversible: record only.)
  Erratum 2026-11-16: superseded in scope by D11-23 (owner decision of 2026-11-16): the gap-closure plans gate the three ungated animations (C014, C015, CHK-04 site) instead of recording them only; the checklist entry and the D-09 brief stay.
- **D11-18:** [Research follow-up] Ledger entry only. It is not resolved in Phase 11. (Question: Privacy manifest and build date open question?; reversible: record only.)

- **D11-19:** [Plan-check follow-up] Yes. Xcode MCP BuildProject cannot do a clean build or select the Release configuration, which counts as a named missing capability, so plan 11-01 runs those builds with xcodebuild and the evidence names the runner for each build. (Question: May clean Debug and Release builds use the CLI?; reversible: runner choice; the results are the same.)

### Runner amendment (owner, 2026-11-14) — overrides D11-08, D11-15 and D11-19 wherever they conflict
- **D11-20:** Xcode MCP only, for every build and test step. CLI `xcodebuild` is allowed in exactly two steps, both owner-approved: (1) one Release-configuration build (`-configuration Release`, generic iOS destination, `CODE_SIGNING_ALLOWED=NO`), because MCP BuildProject cannot select a configuration; (2) one full-suite test run with `-enableCodeCoverage YES`, because MCP cannot collect coverage. There is no clean Debug build by CLI: the Debug warning inventory comes from MCP `BuildProject` (buildForTesting) plus `GetBuildLog` (severity warning). There is no CLI fallback anywhere else. An MCP timeout, an empty result or a missing message is reported to the owner as a blocker and is never re-run with the CLI. The evidence names the runner for every build and run. Earlier CLI builds done during research and the interrupted plan 11-01 CLI run are not evidence. — **Reversibility:** reversible — runner policy only.

- **D11-21:** (owner, 2026-11-14) The Release device build's store-validation warning "All interface orientations must be supported unless the app requires full screen." is fixed in Phase 11 by adding UIInterfaceOrientationPortraitUpsideDown to UISupportedInterfaceOrientations~ipad in drinkpulse/Info.plist (plan 11-11). UIRequiresFullScreen is not added and TARGETED_DEVICE_FAMILY stays 1,2. This is the only production-file change in Phase 11. The owner approved exactly one more CLI Release device build to confirm the fix. — **Reversibility:** reversible — a single plist array entry.
  Erratum 2026-11-16: Info.plist remains the only production change of plans 11-01 to 11-11; the gap-closure plans 11-14 to 11-21 change further production files (Reduce Motion gating, AX5 layout and the audit groups, owner decisions D11-23 to D11-25), so this sentence no longer holds for the phase as a whole.

- **D11-22:** (owner, 2026-11-14) The accessibility audit's first run found 311 distinct issue keys (385 reports; contrast 144, dynamicType 73, textClipped 57, sufficientElementDescription 21, hitRegion 16). They are recorded as open VER-03 findings, not allow-listed and not fixed in Phase 11. The record holds counts, digests of the out-of-git result files, and a grouping by probable root cause per screen and audit type. The debt ledger gets grouped rows, not 311 per-key rows. A new pending todo covers the fixes, and each fix needs an owner D-09 brief. `AccessibilityAuditUITests` stays in the repo, gated behind an environment flag with the same pattern as `DP_RUN_FLASH_HARNESS`, so it skips by default and the full suite does not go red. This supersedes D11-12's "allow-list, green run" contract. Plans 11-04, 11-05 and 11-10 treat the audit class as skipped-by-gate (not a failure) and the VER-03 automated column reports "audit run: 16 methods red, 311 open findings". — **Reversibility:** reversible — test gating and records only.
  Erratum 2026-11-16: the audit record needs two corrections. The 311 figure is the byte-wise distinct key count (also the line count of the key file; 385 reports); the "254 distinct keys, 57 repeats" claim of 11-VERIFICATION.md is a `sort -u` locale artifact (emoji element names collate equal in pl_PL.UTF-8) and is not a count. The real defect of the record is that 9 of the 16 method rows ran in dark appearance and are unreliable; see 11-EVIDENCE.md Record integrity. The D11-22 contract (no allow-list, gated class) is unchanged by the erratum.

### Gap-closure amendments (owner, 2026-11-16, /gsd-plan-phase 11 --gaps)
- **D11-23:** Reduce Motion: change. Gate the three ungated animations (C014 ConsumptionOverviewCard, C015 HistoryCalendarView, and the CHK-04 site DPArcProgress) on accessibilityReduceMotion with the existing `reduceMotion ? nil : animation` pattern, add a gated launch-argument route that forces Reduce Motion in UI tests (never in production paths) and at least one UI test per site; the owner re-runs CHK-04, CHK-05 and CHK-06 and re-checks T12 (CHK-03). — **Reversibility:** reversible — three view modifiers and a test-only launch route.

- **D11-24:** AX5 text size: change per C016, in a single plan (11-16), for Home, Insights, Add Drink steps 1 and 2, Settings Preferences and Onboarding, with a UI test at AX5 for each screen; the owner re-observes CHK-07. — **Reversibility:** reversible — layout changes in SwiftUI views, no data or schema effect.

- **D11-25:** Audit groups: fix all groups A11Y-AUDIT-G01 to G09 now, split by screen. This is the owner's D-09 decision for the groups. Each user-facing fix gets a UI test; the final step re-runs the gated audit class until it passes; the gate may stay as a documented opt-in. — **Reversibility:** reversible — accessibility fixes in views and the test harness.

- **D11-26:** Audit runner: the owner sets DP_RUN_A11Y_AUDIT=1 temporarily in the drinkpulse scheme Test action environment, the run uses Xcode MCP RunSomeTests on AccessibilityAuditUITests, and the owner removes the variable afterwards. The CLI is not an approved runner for this run. Counts and digests go to 11-EVIDENCE.md. — **Reversibility:** reversible — a scheme environment variable set and removed by the owner.

- **D11-27:** OBS-A and OBS-C stay pending; no fixes are planned for them in Phase 11 gap closure. — **Reversibility:** reversible — a deferral; the briefs stay open.

- **D11-28:** (owner, 2026-11-16, at the plan 11-16 Task 3 decision checkpoint) Narrow, documented exception to the plan 11-16 "no allow-list" rule for system-owned `Form` controls at AX5. Scope: `dynamicType` and `textClipped` findings only, on Add Drink step 2 (element keys `Volume`, `Strength`, `Amount`, `none#type=nil`) and, only after a reasonable app-side attempt fails, the same class of finding on Settings Preferences. It is implemented as an explicit per-call `exemptElementKeys` set in the AX5 UI test, with a comment citing this decision; it is not a blanket mute. Every other finding on those screens, every finding on other screens, and every contrast, hit-region or description finding still fails. The text-size behavior of those screens is judged by the owner's CHK-07 re-observation (plan 11-16 Task 5). Reason: Form controls (Picker, Menu, Button, DatePicker and TextField internals) are flagged at AX5 even with default text styles, while the same text outside a Form passes; six app-side approaches did not clear them (see 11-DECISION-C016.md). — **Reversibility:** reversible — delete the `exemptElementKeys` argument in the AX5 UI tests; the test then goes red again.

### Claude's Discretion
- None. The owner answered every question that was asked.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- UI test suites mirror the features: `drinkpulseUITests/Features/{AddDrink,Dashboard,History,Insights,Onboarding,Settings,Shell}`.
- The chart accessibility code is in `drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift` and `WeekdayBarChart+Accessibility.swift` (Audio Graph descriptors).
- There is a durable VoiceOver UI test from Phase 09-05 (`XCUIVoiceOverService` pattern: skip on failedToStart).
- Baseline evidence format: `08-BASELINE.md` and `.json`, and `10-EVIDENCE.md` (toolchain, zero-warning gate, guards, coverage).

### Established Patterns
- Gate commands and the coverage command are in AGENTS.md. A full-suite pass is required at milestone close.
- Launch-argument test hooks (for example `-dp_onboarding_done YES`). The simulator system locale is Polish, so tests must never match system UI by its localized label.
- Owner-run checklists record results per item (09-UAT.md and 10-DEVICE-SESSION.md style).

### Integration Points
- Living docs to reconcile at the end: README, PROJECT.md, ROADMAP.md, REQUIREMENTS.md (MOD-04 and VER-01 to VER-03), current-focus.md, open-questions.md and DEVLOG.

</code_context>

<specifics>
## Specific Ideas

- Phase 08 found exactly one warning: the `@Entry` closure warning (`dismissSheet`), which Phase 09 addressed. The fresh Phase 11 build must confirm whether any deprecation warnings remain.
- Phase 05 skipped checks: `05-UAT.md` test 4 (Reduce Motion gates both charts), test 5 (AlcoholAreaChart Audio Graph) and test 6 (WeekdayBarChart Audio Graph).

</specifics>

<deferred>
## Deferred Ideas

- Re-running the phase verifier for Phases 08–10, which would refresh the stale 09-VERIFICATION.md. This belongs to separate verification work, not Phase 11.
- Fixing the known red or flaky UI tests and D1. These stay with their existing todos.
- A fresh device pass on the final build, and device-level accessibility checks.

</deferred>
