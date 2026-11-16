# Phase 11: iOS 27 Release Verification - Research

**Researched:** 2026-11-14
**Domain:** Release-verification evidence for an iOS 27 migration (build warnings, regression suites, flow proof, accessibility checks, debt ledger). No production code changes.
**Confidence:** HIGH for warning inventory, test inventory and debt inventory (measured or read this session); MEDIUM for simulator accessibility capabilities (docs conflict, see A1).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Readiness of prior phases**
- Proceed without re-verifying Phases 08–10. Treat them as done, based on their closure plans: 08-08, 09-10 (closed with D1 deferred) and 10-14. Phase 11 does not re-run the phase verifier for 08, 09 or 10. The stale `09-VERIFICATION.md` (gaps_found, written before 09-10) and the "stale" status of 08 and 10 are listed in the Phase 11 debt ledger as known record states. They are not fixed or rewritten here.

**Regression suite scope (VER-01)**
- No test or app fixes in Phase 11 for the known non-green items. Each one is recorded as an open limitation with its cause, todo or open-question link, and owner. VER-01 passes with these named exceptions. The items are: `InsightsUITests.test_heroCard_holdsHeight_whenSwitchingToAllTimeScope` (pre-existing failure), the two `HistoryInteractionUITests` edit tests that fail when run alone (todo `2026-11-13-history-edit-uitests-failing.md`), the Export dismiss UI test flake (todo `2026-11-13-export-dismiss-uitest-flaky.md`), and the two D1 crash harness tests gated behind `DP_RUN_FLASH_HARNESS` (todo `2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md`). A new failure that is not on this list is a blocker. It is not added as a silent exception.

**Accessibility human checks (VER-03)**
- The owner runs the human accessibility checklist on the iOS 27 simulator, not on the iPhone. The checklist covers: VoiceOver on both chart Audio Graphs (AlcoholAreaChart and WeekdayBarChart), Reduce Motion, Dynamic Type through AX5, light and dark appearance, and Increase Contrast. Each item is recorded as passed, failed or explicitly open. The evidence states that the run was on a simulator, not a device. Automated results (XCUITest and accessibility audits) and human results are kept in separate columns.

**Core flow proof (VER-02)**
- Automated UI tests cover onboarding, startup/retry, add/edit/delete, History list and calendar, Insights, settings and backup export/import on iOS 27. The proof that existing data is preserved cites the Phase 10 device session (`10-DEVICE-SESSION.md`: in-place upgrade, import round trip, edit/delete, 214 events before and after). No new device session is planned. The evidence states a limitation: the device proof was made before the Phase 09-10 code changes, which reverted the Dashboard container and gated the harness tests.

**Toolchain and destination (owner update, 2026-11-14)**
- Phase 11 evidence uses the installed Xcode 27.2 (27B52) with the iOS 27.2 SDK (`iphoneos27.2` / `iphonesimulator27.2`), and the iPhone 18 Pro simulator on the iOS 27.2 runtime as the primary destination. The iPhone 18 Pro Max on iOS 27.2 is the secondary destination. This replaces the Phase 08 baseline toolchain (Xcode 27.0, 27A266a), so VER-01 evidence must record the toolchain change and must not reuse Phase 08 version strings. `IPHONEOS_DEPLOYMENT_TARGET` stays 27.0 in every target and configuration. The minimum OS is a product decision, and raising it is out of scope.

**Decided autonomously**
- [Warnings] Q: 'How to find deprecation warnings (MOD-04)?' → Selected: 'Do clean Debug and Release builds, extract every warning from the logs, classify each one as app-owned or external, and fix app-owned warnings at the source. Any fix that changes behavior or data goes through the Phase 08 D-09 brief first. An external warning records its official source, impact and follow-up.' — evidence method only; changing it later does not affect code.
- [Evidence] Q: 'Where does the evidence go?' → Selected: 'One 11-EVIDENCE.md with the exact commands, Xcode and Swift versions, SDK and runtime, destination, counts and log hashes. Raw logs stay outside git (Phase 08 D-13 pattern).' — document layout only.
- [Tooling] Q: 'How are builds and tests run?' → Selected: 'Xcode MCP first. The CLI xcodebuild is used only where the MCP test timeout is known to break long UI suites (Phase 09-03 precedent), and the evidence records which runner was used. Scoped runs come first, then the full suite.' — runner choice; the results are the same.
- [Phase 05 debt] Q: 'How are the three skipped Phase 05 checks handled?' → Selected: 'Fold the Reduce Motion check and both Audio Graph checks into the VER-03 human checklist, each linked back to the archived 05-UAT.md tests 4, 5 and 6, and record the outcome against each one.' — checklist mapping only.
- [Debt ledger] Q: 'How is the do-not-silently-close-debt criterion met?' → Selected: 'Add a ledger table that lists D1, WINDOWS.md row 7 (Domain coverage), the open-questions items, the pending todos and the prior-phase verification record states, each with its status and owner. Nothing is closed without evidence.' — record only.
- [Discoveries] Q: 'How is SC5 (modernization discoveries) checked?' → Selected: 'Cross-check C001 to C013 and the Phase 10 decisions F2 to F4 and the device finding against their decision records, and confirm that each one has a recorded analysis and outcome.' — read-only audit.

### Claude's Discretion
- None. The owner answered every question that was asked.

### Deferred Ideas (OUT OF SCOPE)
- Re-running the phase verifier for Phases 08–10, which would refresh the stale 09-VERIFICATION.md. This belongs to separate verification work, not Phase 11.
- Fixing the known red or flaky UI tests and D1. These stay with their existing todos.
- A fresh device pass on the final build, and device-level accessibility checks.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MOD-04 | App-owned deprecated API warnings resolved without suppression; external blocked ones documented with source, impact, follow-up | Fresh clean Debug (build-for-testing, all 3 targets) and Release builds measured on 2026-11-14: 0 Swift/ld/clang warnings, 0 deprecation text. See "MOD-04 Warning Inventory". Nothing to fix; evidence capture only. |
| VER-01 | Debug and Release builds succeed; unit/integration/UI suites pass on iOS 27; compiler, SDK, destination, limitations recorded | Toolchain facts, runner choice, commands, expected non-green list, evidence fields, coverage route. See "VER-01". |
| VER-02 | Onboarding, startup/retry, add/edit/delete, History list/calendar, Insights, settings, backup export/import work without loss | Flow-to-test map, three coverage gaps (edit has only red or indirect tests, import has no UI test, Phase 10 device proof predates 9 changed production files). See "VER-02". |
| VER-03 | VoiceOver incl. both Audio Graphs, Reduce Motion, Dynamic Type to AX5, light/dark, Increase Contrast; automated vs human distinguished | Automatable vs human-only split, simulator capability conflict, checklist mapped to 05-UAT tests 4-6 and WINDOWS rows. See "VER-03". |
</phase_requirements>

## Summary

Phase 11 is an evidence phase. Research measured the two things the planner most needs. First, the warning inventory is already clean: a fresh `clean build-for-testing` (app, unit and UI test targets, Debug) and a fresh `clean build` (Release) on Xcode 27.2 / Swift 6.4.2 produced zero Swift, linker or clang warnings and no deprecation text. The only `warning:` lines are `appintentsmetadataprocessor` tool notes ("no AppIntents.framework dependency found"), identical to Phase 10. The Phase 08 `@Entry` `dismissSheet` warning is gone: `AddDrinkView.swift` now uses `@Environment(\.dismiss) private var dismissSheet` and passes a `DismissAction`. So MOD-04 needs no source change; the plan only has to re-capture this inventory on the canonical routes and record it.

Second, three real coverage gaps exist that CONTEXT does not mention and the plan must record explicitly rather than hide. (1) Backup **import** has no UI test: `DataSection` uses `fileImporter`, a system picker; only unit round-trip suites and the Phase 10 device step cover it. (2) **Edit** UI coverage is thin: the two History edit tests that cover name/notes and category edit are on the known-red list, leaving `EditVolumeIntegrityUITests` and `DuplicateEditPersistenceUITests` as the only green edit proof. (3) The Phase 10 device proof predates **nine production files** changed since commit `a38a75f` (the end of plan 10-14), including `StoreBootstrap.swift` (+117 lines of recovery/rollback), `HealthService.swift`, `WeeklySummaryService.swift`, `DashboardView.swift` and the Settings version footer. CONTEXT's limitation sentence names only the Dashboard revert and harness gating; it understates this. No automated accessibility audit (`performAccessibilityAudit`) exists in the repo, yet CONTEXT expects "accessibility audits" as an automated column, so one new test-only class is needed (or the column is empty).

The human accessibility checklist has a capability risk: Apple's accessibility-testing article says VoiceOver is not available on Simulator, while Phase 09-05 ran `XCUIVoiceOverService` on the iOS 27 simulator (3 of 3 passes, 0 skipped). `XCUIVoiceOverService` has no rotor API, so the Audio Graph action cannot be automated at all. The checklist must start with a probe and is allowed to record the two Audio Graph items as "explicitly open".

**Primary recommendation:** Capture MOD-04/VER-01 evidence as one `11-EVIDENCE.md` (clean Debug+Release builds, scoped MCP runs, one detached CLI full suite with coverage), add one test-only `AccessibilityAuditUITests` class for the automated accessibility column, run the human checklist on a cloned simulator, and write a debt ledger that lists (never closes) every open item including the WINDOWS rows that overlap the checklist.

## Architectural Responsibility Map

Not a multi-tier capability phase. Verification responsibilities by layer:

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Warning inventory | Build system (Xcode/xcodebuild logs) | — | Warnings are compiler/linker output; only a build produces them |
| Regression proof | Test targets (`drinkpulseTests` Swift Testing, `drinkpulseUITests` XCUITest) | Simulator | Unit proves logic; UI tests prove wiring |
| Existing-data preservation | Migration unit suites (automated) | Owner device session (Phase 10, historical) | UI tests use an in-memory seeded store (`dp_uitest`), so they cannot prove stored-data preservation |
| Accessibility | Automated audit + XCUITest (partial) | Human simulator checklist | Audio Graph rotor, Reduce Motion, Increase Contrast need a human or system setting |
| Debt/decision reconciliation | Planning documents | — | Read-only audit |

## Standard Stack

No packages are installed or added. The "stack" is the Apple toolchain already in use.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Xcode | 27.2 (27B52) [VERIFIED: `xcodebuild -version` run this session] | Build/test | Project toolchain; matches 10-EVIDENCE |
| Swift | 6.4.2 (swiftlang-6.4.2.1.9), language mode `SWIFT_VERSION = 6.0` [VERIFIED: `swift --version` this session; project.pbxproj:311,466,497,512] | Compiler | Phase 08 baseline |
| iOS Simulator SDK | iphonesimulator 27.2 [VERIFIED: `xcrun --sdk iphonesimulator --show-sdk-version` -> `27.2`] | SDK | |
| iOS runtime | `com.apple.CoreSimulator.SimRuntime.iOS-27-2` (build 24B8117) [VERIFIED: `xcrun simctl list runtimes`] | Destination | A second 27.2 runtime (`...iOS-27-2-iPhone19-4`, 24B91016s) and 27.0 (24A434) also exist; two simulators named "iPhone 18 Pro" exist (one per 27.0 and 27.2 runtime), so evidence must name the runtime build, not just the model |
| Primary destination (owner, 2026-11-14) | Xcode MCP active destination `iPhone 18 Pro`, `osVersion` 27.2, group Simulators, `sdkDisplayName` "Simulator - iOS 27.2" [VERIFIED: `XcodeListRunDestinations` with workspace `windowtab-yFC8xpmPte` this session]. Secondary: `iPhone 18 Pro Max (27.2)` [VERIFIED: same call] | Destination | Use these for every MCP build/test. For CLI runs resolve the matching UDID at runtime with `xcrun simctl list devices available` under the iOS 27.2 runtime; do not record it. Note `iPhone 18 Pro Max (27.0)` is a different destination. |
| Xcode MCP | `BuildProject`, `RunSomeTests`, `RunAllTests`, `GetBuildLog` | First-choice runner per AGENTS.md | Project policy |
| `xcrun xcresulttool get test-results summary/tests` [VERIFIED: `--help` this session] | Xcode 27.2 | Counts and failed-test list from `.xcresult` | |
| `xcrun xccov view --report` | Xcode 27.2 | Coverage per AGENTS.md | Project policy |
| `xcrun simctl ui <udid> appearance\|increase_contrast\|...` [VERIFIED: help output this session] | Xcode 27.2 | Light/dark and Increase Contrast on a simulator | Only scriptable route found for these two |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CLI full-suite with coverage | Xcode MCP `RunAllTests` | MCP completed a full run in the Phase 09 closing run (821/826, per the export-flake todo) so MCP is viable, but the shared scheme has no coverage setting (`drinkpulse.xcscheme` has `shouldAutocreateTestPlan = "YES"` and no `codeCoverageEnabled`), so MCP cannot produce the coverage report AGENTS.md requires at milestone close. Two full runs (about 30 min each) would be wasteful. |
| New audit test class | Manual Accessibility Inspector audits | Inspector results would be human evidence only; CONTEXT wants an automated audit column |

**Package legitimacy:** no external packages are installed in this phase. Audit section not applicable. `gsd_run query package-legitimacy` was not run.

## MOD-04 Warning Inventory (measured 2026-11-14)

Method (for the plan to repeat on the canonical routes):

```bash
# Debug, whole project (app + drinkpulseTests + drinkpulseUITests), clean
xcodebuild clean build-for-testing -project drinkpulse.xcodeproj -scheme drinkpulse \
  -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath <fresh dir> > debug-build.log 2>&1
# Release, app target, clean
xcodebuild clean build -project drinkpulse.xcodeproj -scheme drinkpulse \
  -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath <fresh dir> > release-build.log 2>&1
# Gate (same pattern Phase 10 used, plus a plain count)
grep -cE '(\.swift:[0-9]+:[0-9]+: |ld: |clang: )warning:' <log>   # must print 0
grep -c 'warning:' <log>                                          # list every hit and classify
```

Result at HEAD `0c1cc198b20d3fc75abbf6852bd4c451d383e843`, working tree clean (`git status --short` empty), Xcode 27.2 (27B52), Swift 6.4.2:

| Run | Result | Total `warning:` lines | Swift/ld/clang warnings | Log SHA-256 (scratch logs, will be regenerated) |
|-----|--------|-----------------------|-------------------------|------|
| Debug `clean build-for-testing`, 3 targets | `** TEST BUILD SUCCEEDED **`, 0 `error:` | 3 | 0 | `a32bcd51...4d1` |
| Release `clean build`, app | `** BUILD SUCCEEDED **` | 1 | 0 | `0ebca4ea...933` |

The four `warning:` lines are all `appintentsmetadataprocessor[...] warning: Metadata extraction skipped, no AppIntents.framework dependency found`. Classification: tool note, not a compiler or deprecation diagnostic; the app does not use App Intents; identical to `10-EVIDENCE.md` ("three appintentsmetadataprocessor ... tool notes"). Record as external/tooling, impact none, follow-up none. `grep -c "dismissSheet|@Entry"` on the Debug log is 0, and `grep -rn "@Entry" drinkpulse` finds no match in source: the Phase 08 `@Entry` warning (`08-BASELINE.md`: "also emits the `@Entry` closure warning ... `dismissSheet` closure may invalidate dependents") no longer exists. The source now reads `@Environment(\.dismiss) private var dismissSheet` [VERIFIED: drinkpulse/Features/AddDrink/AddDrinkView.swift:5] and `let dismissSheet: DismissAction` [VERIFIED: DrinkTypeGridView.swift:4].

Notes for the plan:
- The builds were run by CLI into a scratchpad derived-data path with `generic/platform=iOS Simulator` (arm64 + x86_64). Xcode MCP `BuildProject` has no clean and no configuration parameter (tool schema: only `buildForTesting`, `workspaceIdentifier`), so a clean Debug and any Release build are the "named missing capability" that justifies CLI under AGENTS.md. An MCP incremental build at the same HEAD also succeeded (`errors: []`, 3 s) but a 3-second incremental build proves nothing about warnings. Record both facts.
- No `-warnings-as-errors`/`SWIFT_TREAT_WARNINGS_AS_ERRORS` is set [VERIFIED: grep of project.pbxproj returned no match]. The zero-warning claim therefore rests on the log scan, not on the compiler failing.
- "Deprecation" appears nowhere in either log (`grep -E "warning:|deprecated"` returned only the tool notes).
- Outcome for MOD-04: app-owned deprecation warnings = 0, externally blocked = none, no source change. MOD-04 can be marked complete from this evidence. Optional hardening (not recommended in scope): none.

## Architecture Patterns

### Evidence flow

```
Fresh clean builds (CLI, named capability: clean + Release)
   -> warning scan -> classify app-owned vs external -> MOD-04 row
Scoped runs (Xcode MCP RunSomeTests; changed-area classes first)
   -> full suite once (CLI, detached, -enableCodeCoverage YES, xcresult)
        -> xcresulttool summary -> map every failure to the CONTEXT exception list
              match   -> "limitation" row (cause, todo, owner)
              no match -> BLOCKER (stop, do not record as exception)
        -> xccov -> coverage vs AGENTS per-layer targets
Automated accessibility (new AccessibilityAuditUITests + existing VO/AX5 tests)
Human simulator checklist (cloned simulator) -> per-item pass/fail/open
Debt ledger + SC5 discovery table (read-only)
   -> 11-EVIDENCE.md (+ living-doc reconciliation)
```

### Recommended document layout
```
.planning/phases/11-ios-27-release-verification/
├── 11-EVIDENCE.md          # toolchain, commands, counts, hashes, limitations, ledger, SC5 table
├── 11-A11Y-CHECKLIST.md    # owner-run simulator checklist, per-item result (09-UAT / 10-DEVICE-SESSION style)
raw logs: ~/Library/Logs/DrinkPulse/phase-11-ios27/<UTC stamp>/   # outside git; ~/Library/Logs/DrinkPulse/phase-08-ios27 already exists
```

### Pattern 1: Detached full-suite run (Phase 10 precedent)
**What:** Run the ~30 minute suite as a background job writing a log and an exit file; never read a timeout as a result.
**Source:** `10-EVIDENCE.md` "Full suite": `xcodebuild test ... -derivedDataPath build/p10-full -resultBundlePath build/p10-full.xcresult -enableCodeCoverage YES -collect-test-diagnostics never`, exit file `0`, "Executed 93 tests, with 0 failures (0 unexpected) in 1714.111 seconds" for the UI bundle.
```bash
# Resolve the simulator at runtime; do not record the UDID (machine-specific per AGENTS.md)
xcrun simctl list devices available            # pick "iPhone 18 Pro" under the iOS 27.2 runtime (owner's primary destination)
xcrun simctl bootstatus "$UDID" -b
xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath <dir> \
  -resultBundlePath <dir>.xcresult -enableCodeCoverage YES -collect-test-diagnostics never \
  > full.log 2>&1; echo $? > full.exit
xcrun xcresulttool get test-results summary --path <dir>.xcresult      # counts + failures
xcrun xccov view --report --only-targets <dir>.xcresult                # AGENTS.md coverage command
```
Do NOT set `TEST_RUNNER_DP_RUN_FLASH_HARNESS`; the two D1 tests must report Skipped.

### Anti-Patterns to Avoid
- **Treating the MCP test backend timeout or an incomplete run as a pass or fail.** Precedent: `09-03-SUMMARY.md` ("never interpret an MCP timeout as a test result").
- **Adding a failing test to the suite.** A new red test is a "new failure not on the list" and a blocker by CONTEXT. Audit-test issues must be allow-listed by ledger id (see Code Examples), not left red.
- **Running the human checklist on the same simulator as the automated suite.** The checklist changes simulator-global settings (text size, Increase Contrast, appearance, Reduce Motion, VoiceOver) that persist and distort automated results.
- **Recording a simulator UDID in a committed doc.** AGENTS.md: machine-specific.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Counting passed/failed/skipped tests | grep over xcodebuild text | `xcrun xcresulttool get test-results summary` / `tests` | Structured, includes skip reasons |
| Coverage numbers | custom parsing | `xcrun xccov view --report --json` | AGENTS.md command; Phase 10 used it |
| Accessibility audit | hand-written contrast/clipping checks | `XCUIApplication.performAccessibilityAudit(for:_:)` | Same engine as Accessibility Inspector [CITED: Accessibility "Performing accessibility audits for your app"] |
| Light/dark, Increase Contrast switching on a simulator | UI automation of Settings | `xcrun simctl ui <udid> appearance light\|dark`, `increase_contrast enabled\|disabled`; or `XCUIDevice.shared.appearance` inside a test [CITED: XCUIDevice.appearance docs] | System-supported |
| Dynamic Type for a test | UI automation of Settings | launch argument `-UIPreferredContentSizeCategoryName` as in `HistoryDynamicTypeUITests` | Already proven in this repo |

**Key insight:** every metric in this phase must come from a tool output that can be hashed and re-read; hand-assembled numbers are what Phase 08/10 evidence formats were built to avoid.

## VER-01: Builds, Tests, Runner, Evidence Fields

### Runner policy (CONTEXT: MCP first)
- Resolve the workspace first: `XcodeListWorkspaces` returned two entries this session (`.../drinkpulse-diag/minimal-repro/MinimalRepro.xcodeproj` and `.../drinkpulse/drinkpulse.xcodeproj`). Take the one whose path ends in `drinkpulse.xcodeproj`; pass `workspaceIdentifier` on every call. Never hard-code the identifier (AGENTS.md). Branch is `verify/phase-08-reverification-2026-11-08`, a normal checkout, so MCP applies (not the worktree exception).
- Scoped runs: MCP `RunSomeTests` per changed-area class. Phase 11 changes no app code, so "scoped" means the classes tied to each VER-02 flow plus any new audit class.
- Full suite: one detached CLI run with coverage (see Alternatives). Named missing MCP capability: coverage collection (no coverage setting in the shared scheme). Record this explicitly in `11-EVIDENCE.md` along with the runner used for each row. Open question Q3 asks the owner to confirm this reading of "CLI only where MCP is known to break".
- Precedent facts the plan should cite precisely: Phase 09-03 used persistent CLI because MCP's long-test backend timed out on a 49-test, 869 s UI selection; the Phase 09 closing run later completed a full MCP `RunAllTests` (821 of 826 passed, per `2026-11-13-export-dismiss-uitest-flaky.md`). So MCP timeout behavior is inconsistent; the evidence must name the runner per run and never infer a result from a timeout.

### Expected non-green list (record as limitations, do not fix)
| Item | Cause/link | Expected in a full run |
|------|-----------|------------------------|
| `InsightsUITests.test_heroCard_holdsHeight_whenSwitchingToAllTimeScope` | open-questions "Insights hero card height test fails (pre-existing)"; Week chart y=323.0 vs All y=320.0, tolerance 1.0; fails on `fbd37fa` and `2cb2649` too | Fails deterministically |
| `HistoryInteractionUITests.test_editCustomNameAndNotes_persist`, `test_editCategoryChange_persists` | todo `2026-11-13-history-edit-uitests-failing.md` (failures at `HistoryInteractionUITests.swift:165` and `:220`) | Fail (todo says deterministic, including on retry) |
| `ExportUITests.test_export_dismissWithoutSaving_showsNoFailureAlert` | todo `2026-11-13-export-dismiss-uitest-flaky.md`; `ExportUITests.swift:47` "Save panel should present before dismissal" | Intermittent |
| `SheetDismissTabSwitchUITests` sheet-mode cycle and empty-sheet tests | todo `2026-09-18-...flash...`; gated by `ProcessInfo.processInfo.environment["DP_RUN_FLASH_HARNESS"] == "1"` [VERIFIED: SheetDismissTabSwitchUITests.swift:73] | Reported **Skipped** (not failed). The scheme `SkippedTests` approach was removed in `7631c4d` because "The scheme SkippedTests entries were ignored by the auto-created test plan" |
| `HistoryInteractionUITests.test_segmentSwitch_alternatingDirection_endsInCorrectState` | single-run flake in Phase 10 (`10-13` run), passed on re-run (open-questions) | Possible; **not on CONTEXT's list**, see Q4 |

Open item carried from 09-10: a full `RunAllTests`-style run has never confirmed end to end that the two D1 tests stay skipped (only `GetTestList` did, then `7631c4d` verified via `RunSomeTests`). The Phase 11 full run is the first to close that; record it.

Classification rule to put in the plan: map every failure by exact test identifier to this table. A match is a limitation row. A non-match is a blocker. A listed test that unexpectedly passes is also recorded (the flake may have gone) without removing it from the todo.

### Toolchain change record (required by the owner update)
VER-01 evidence must contain an explicit "toolchain change" row and must not reuse Phase 08 strings. Facts to cite:
- Phase 08 baseline: Xcode 27.0 (27A266a), Apple Swift 6.4 (`swiftlang-6.4.0.34.1`), iOS 27.0 SDK, iPhone 18 Pro iOS 27.0 build 24A434 [VERIFIED: 08-BASELINE.md lines 3-8: "Xcode 27.0 (27A266a), Apple Swift 6.4 (`swiftlang-6.4.0.34.1`), and the iOS 27.0 SDK ... iPhone 18 Pro ... iOS 27.0 build 24A434"].
- Phase 10 already ran on Xcode 27.2 (27B52), Swift 6.4.2, iphonesimulator 27.2, iPhone 17 iOS 27.2 [VERIFIED: 10-EVIDENCE.md "Toolchain and destination"]. So the change from the Phase 08 baseline happened between Phases 08 and 10; `09-RETAIN-EVIDENCE.md` (2026-09-19) records Xcode 27.0 (27A266a) on the iPhone 18 Pro iOS 27.0 simulator [VERIFIED: its environment table], so Phase 09 evidence mixes toolchains.
- Phase 11 (this research): Xcode 27.2 (27B52), Swift 6.4.2 (`swiftlang-6.4.2.1.9`), SDK iphonesimulator 27.2, primary destination iPhone 18 Pro on iOS 27.2 (differs from Phase 10's iPhone 17).
- Deployment target unchanged: `IPHONEOS_DEPLOYMENT_TARGET = 27.0` at project.pbxproj lines 307, 370, 429, 453, 484, 508 [VERIFIED: grep output this session]; `SWIFT_VERSION = 6.0` at 311, 466, 497, 512. A 27.2 SDK with a 27.0 deployment target is intended; do not propose raising it. Evidence should say "built with SDK 27.2, deployment target 27.0, run on 27.2 runtime"; it therefore does not test the 27.0 runtime (a limitation to record; the 27.0 runtime exists on this machine but is not an owner-selected destination).
- Consequence for older evidence: the Phase 10 coverage, 214-event device proof and zero-warning claims were made on 27.2 or earlier code; the Phase 11 rerun is on 27.2 with newer code, so it is the first Release build and first full suite on this exact toolchain+HEAD.

My scratch builds used `generic/platform=iOS Simulator` (Xcode 27.2 SDK), not the owner's primary destination. The warning result is not destination-specific for Swift diagnostics, but the plan must repeat the Debug build on the primary destination (MCP `BuildProject` builds for the active destination, which is already iPhone 18 Pro 27.2).

### Evidence fields (each run row)
Date/time, git HEAD hash and clean-tree flag, Xcode `27.2 (27B52)`, Swift `6.4.2`, language mode `6.0`, SDK `iphonesimulator 27.2`, runtime name and build, device model (not UDID), runner (Xcode MCP or CLI) plus the named reason if CLI, exact command, exit status, counts (total/passed/failed/skipped per bundle), failed-test list mapped to the exception table, log SHA-256 and the out-of-git directory, coverage numbers, limitations. Baseline to compare: Phase 10 full suite 678 unit tests in 59 suites, UI 93 tests in 1714 s, overall coverage 94.61 percent [VERIFIED: 10-EVIDENCE.md "Full suite" and "Coverage"]. Test counts have grown since (Phase 09 closing run reported 826 total); do not require equality, record the new numbers.

### Coverage
Rerun is justified, not optional: nine production files changed after the Phase 10 coverage measurement (see VER-02 limitation). Targets per AGENTS.md: overall at least 90 percent, Services at least 85 percent, Domain 100 percent (known-short: WINDOWS rows 1 and 7, Domain aggregate 90.06 percent non-Persistence at Phase 10; list, do not close). `StoreBootstrap.swift` was 96.1 percent at Phase 10 and changed by +117 lines since; report its new value.

### Release
Only the app builds in Release in the scheme flow used here (Release build of the app target succeeded). No Release test run is required by VER-01 ("Debug and Release builds succeed ... suites pass on iOS 27"); Debug tests are the project norm (`xcodebuild test -configuration Debug` in AGENTS.md).

## VER-02: Flow to Test Map

Test names and counts read from the files this session (method names from `grep func test_`).

| Flow | UI test coverage (class: tests) | Status / gap |
|------|---------------------------------|--------------|
| Onboarding | `OnboardingFlowUITests` (full walkthrough, back button, profile inputs carry into Settings); `OnboardingHealthStepUITests`; `OnboardingLocaleDefaultUITests` (enUS, deDE); `OnboardingWeeklySummaryUITests`; `LaunchHandoffUITests` (fresh launch lands on onboarding); `OnboardingAuthorityUITests` | Covered |
| Startup / retry | `StartupErrorUITests` (`test_storeFailure_showsFullScreenErrorWithRetryAndDiagnosticAction`, `test_retryButton_reattemptsFullSequence_andReturnsToErrorScreenOnRepeatedFailure`, launch arg `dp_uitest_force_store_failure`); `LaunchHandoffUITests.test_onboardedLaunch_landsOnHomeWithinTimeout`; `WeeklySummaryTapUITests` cold/warm | Covered |
| Add | `AddDrinkFlowUITests` (6), `VolumeServingUITests`, `CurrencyUITests`, `CustomNameAutocompleteUITests`, `AddDrinkPickerFilterUITests`, `HealthWriteHooksUITests` (4), `ShellNavigationUITests` (Add Drink sheet from every tab, dismiss returns to prior tab, VoiceOver Cancel) | Covered |
| Edit | Green: `EditVolumeIntegrityUITests.test_editUntouched_preservesOriginal500mlAsFlOz`, `DuplicateEditPersistenceUITests` (2), `EditDeleteConfirmationUITests`, `HealthWriteHooksUITests.test_healthEnabled_logEditDelete_leavesNoHealthSample`. Red (known): `HistoryInteractionUITests.test_editCustomNameAndNotes_persist`, `test_editCategoryChange_persists` | **Partial gap:** name/notes edit and category-change edit have no green UI proof. Record as limitation with the todo link. The todo states it is unknown whether the app or the tests are wrong; the evidence must say "data-integrity risk undetermined", not "tests stale". |
| Delete | `ContextMenuDeleteConfirmationUITests` (3), `EditDeleteConfirmationUITests` (2), `WrongRowContextMenuTargetUITests` (2), `HistoryInteractionUITests.test_contextMenuDelete_removesEvent`, `HealthWriteHooksUITests.test_healthEnabled_deleteDrink_stillRemovesEvent` | Covered |
| History list | `HistoryInteractionUITests` (+DirectionalTransition 4, +HitTarget 2, +LoadingState, +Pagination), `HistoryUnitDisplayUITests`, `HistoryDynamicTypeUITests` | Covered (minus the two edit tests) |
| History calendar | `HistoryInteractionUITests.test_segmentSwitch_togglesListAndCalendar`, `test_tapCalendarDay_revealsDayDetail`, `test_calendar_selectsTodayInitially_andNeverDeselects` | Covered |
| Insights | `InsightsUITests` (7; hero-height red), `InsightsScrubUITests` (2), `InsightsStreakUITests`, `InsightsDrinkFreeDaysUITests` | Covered except the known-red hero test |
| Settings | `SettingsUITests` (5, incl. appearance mode), `GuidelinePickerUITests` (3), `HealthSettingsUITests`, `ReminderSettingsUITests`, `WeeklySummarySettingsUITests`, `AppVersionUITests` | Covered |
| Export | `ExportUITests` (2; the second is the known flake) | Covered; one test flaky |
| **Import** | **None.** `grep -rniE "import ?(drink|backup)|fileImporter|Import DrinkPulse" drinkpulseUITests` returned no match. `DataSection.swift:34-37` uses `fileImporter(isPresented: $showDPImporter, allowedContentTypes: [.json])`, an out-of-process system document picker | **Gap.** Evidence: unit suites (`DataImporterRoundTripTests`, `DataImporterUpsertTests`, `DataImporterEdgeCaseTests`, `ComprehensiveRoundTripTests`, `SanitizedBackupFixtureTests`, `DrinkControlImporterTests`, per `10-EVIDENCE.md`) and the Phase 10 device step 4 ("all existing records skipped, no duplicates", events 214). Recommendation: record as a limitation. Do not add a UI test in Phase 11: the picker is a system process whose labels follow the simulator's Polish locale (AGENTS.md forbids matching system UI by localized label), and the stated Export precedent shows that save-panel tests are flaky. See Q5. |
| Data preserved | UI tests run on an in-memory seeded store (`dp_uitest`), so they cannot prove preservation. Proof = migration unit suites (`MigrationChainV1Tests`, `MigrationChainV2V3Tests`, `MigrationSweepTests`, `StoreBootstrapTests`, ...) plus Phase 10 device session (214 events before and after, import round trip, edit 1/delete 0 samples) | See limitation below |

### Device-proof limitation (state precisely)
`10-DEVICE-SESSION.md` completed 2026-11-09 and `10-DEVICE-RETEST.md` on 2026-11-10 (plan 10-14 closing commit `a38a75f`). `git diff --stat a38a75f HEAD -- drinkpulse` (run this session) lists 9 changed production files: `Domain/GuidelineLimits.swift` (4 lines), `Domain/Persistence/StoreBootstrap.swift` (117 lines), `Features/Dashboard/DashboardView.swift` (24), `Features/Settings/AppVersionInfo.swift` (new, 121), `Features/Settings/Components/AppVersionFooter.swift` (new, 44), `Features/Settings/SettingsView.swift` (2), `Localizable.xcstrings` (55), `Services/HealthService.swift` (19), `Services/WeeklySummaryService.swift` (42). The Phase 10 post-device review fixes (commits 2026-11-10 16:24 to 18:46) include store move-aside and rollback hardening and the Health update and half-open week fixes. CONTEXT's limitation sentence names only the Dashboard revert and the harness gating. The planner should widen the recorded limitation to this list (Open question Q2) and cite unit coverage of the changed code (`StoreBootstrapTests`, `WeeklySummaryCompletedWeekTests`, Health suites) as the substitute evidence. No new device session is planned (CONTEXT).

## VER-03: Accessibility

### What can be automated on iOS 27 (all sources read this session)
| Check | Automated route | Evidence for the route |
|-------|-----------------|------------------------|
| Accessibility audit | `XCUIApplication.performAccessibilityAudit(for:_:)`; types contrast, elementDetection, hitRegion, sufficientElementDescription, dynamicType, textClipped, trait, all | Signature `public func performAccessibilityAudit(for auditTypes: XCUIAutomation::XCUIAccessibilityAuditType = .all, _ issueHandler: ((XCUIAutomation::XCUIAccessibilityAuditIssue) throws -> Swift::Bool)? = nil) throws` [VERIFIED: Xcode.app .../iPhoneOS.platform/.../XCUIAutomation.framework/Modules/XCUIAutomation.swiftmodule/arm64-apple-ios.swiftinterface:14]; type list [VERIFIED: XCUIAccessibilityAuditTypes.h:15-30 `XCUIAccessibilityAuditTypeDynamicType = (1UL << 16)`, `...TextClipped = (1UL << 17)`, `...Trait = (1UL << 18)`]. Docs: "If the UI test finds any audit issues, it automatically fails." and "Performing accessibility audits is an excellent start ... doesn't guarantee a fully accessible app" [CITED: Accessibility, Performing accessibility audits for your app: Add audits to your UI tests]. **No audit exists in the repo today** [VERIFIED: `grep -rn performAccessibilityAudit . --include='*.swift'` returned nothing]. |
| Dynamic Type to AX5 | launch arg pair `-UIPreferredContentSizeCategoryName` + `"UICTContentSizeCategoryAccessibilityXXXL"` | Already used by `HistoryDynamicTypeUITests.swift:13-26` (`private let ax5Category = "UICTContentSizeCategoryAccessibilityXXXL"`). Only the History row is covered today; Dashboard, Insights, Settings, Add Drink and Onboarding are not. |
| Light / dark | `XCUIDevice.shared.appearance = .dark` [CITED: XCUIAutomation XCUIDevice.appearance] or `xcrun simctl ui <udid> appearance dark` [VERIFIED: simctl help]. `SettingsUITests.test_appearanceMode_reflectsSelectedOption` covers the in-app mode picker only. |
| Increase Contrast | `xcrun simctl ui <udid> increase_contrast enabled` [VERIFIED: simctl help]; no XCUITest API found. Then run the audit's `.contrast` type or look. |
| VoiceOver traversal | `XCUIDevice.shared.voiceOverService`: `enable`, `disable`, `isEnabled`, `currentSpeech`, `moveForward`, `moveBackward`, `moveIn`, `moveOut` [CITED: XCUIVoiceOverService]; `API_AVAILABLE(ios(27.0)...)` [VERIFIED: XCUIDevice.h:67]. Existing pattern: `ShellNavigationUITests.swift:101-143` (enable after launch, skip on `XCUIVoiceOverService.Error.failedToStart`, disable only before launch and in a teardown block). It ran 3 of 3 passes, 0 skipped on the iOS 27 simulator (`09-05-SUMMARY.md`). |
| Reduce Motion | **No automated route found.** No `simctl ui` option or XCUITest API for it appeared in this session's help output or doc searches (the simctl help was read through the `increase_contrast` section; the output beyond that was not retained, so verify with `xcrun simctl ui` before asserting this). Human check via simulator Settings app or Xcode Environment Overrides (Appearance, Dynamic Type, Accessibility with Increase Contrast, Reduce Motion, Smart Invert) [CITED: Xcode, Diagnosing issues in the appearance of a running app]. Unit coverage exists only for the History helper: `drinkpulseTests/Features/History/HistoryViewTests.swift` references `shouldAnimate`. |
| Audio Graph content | Descriptor correctness is unit-tested: `AlcoholAreaChartAXDescriptorTests` (point count, raw y never rounded, injected formatter, empty data) and `WeekdayBarChartAXDescriptorTests`. This proves what the descriptor contains, not that VoiceOver exposes the Audio Graph action. |
| Audio Graph action (rotor) | **Not automatable.** `XCUIVoiceOverService` exposes no rotor or action API (method list above). Human check only. |

### Simulator capability conflict (decide before the checklist)
Apple's article says: "Install your app on a physical device, since VoiceOver isn't available on Simulator." [CITED: Accessibility, Performing accessibility testing for your app: Test with assistive technologies]. The same repo ran `XCUIVoiceOverService.enable()` on the iOS 27.2 simulator and drove focus (09-05, 3 passes, 0 skipped). Whether the Settings app exposes VoiceOver and the Audio Graph rotor action on the iOS 27 simulator for a human is **not established** [ASSUMED: unknown]. The checklist's first step must be a probe (Settings, Accessibility, VoiceOver present? rotor reachable on a chart element?). If either is missing, record both Audio Graph items as "explicitly open: not verifiable on simulator, requires device (deferred per CONTEXT)". That is a permitted outcome under CONTEXT ("passed, failed or explicitly open") and under SC4. Do not infer a pass from the descriptor unit tests.

### Human checklist mapped to archived 05-UAT and WINDOWS rows
| Checklist item | Links to | Automated column | Human column |
|----------------|----------|------------------|--------------|
| VoiceOver, AlcoholAreaChart Audio Graph | 05-UAT test 5 (`result: skipped`; expected "VoiceOver's Rotor > Audio Graph action surfaces every AlcoholAreaChart data point's date + value") | `AlcoholAreaChartAXDescriptorTests` (content only) | pass / fail / open after the probe |
| VoiceOver, WeekdayBarChart Audio Graph | 05-UAT test 6 (`result: skipped`; "additive to the existing per-bar label") | `WeekdayBarChartAXDescriptorTests` | same |
| Reduce Motion on both charts' scrub animation | 05-UAT test 4 (`result: skipped`; "suppresses both charts' callout appear/disappear transition AND the selection-state animation together") and UI-C-08 ("requires human runtime verification") | none (gate is `reduceMotion ? .identity : ...` and `reduceMotion ? nil : .spring(...)` at `AlcoholAreaChart.swift:104-105`, `WeekdayBarChart.swift:85-86`) | pass / fail / open |
| Dynamic Type through AX5 | WINDOWS row 6 (guideline picker glass cards at AX5, B9-3) | new audit at AX5 per tab (`dynamicType`, `textClipped`) + `HistoryDynamicTypeUITests` | observe all tabs, Add Drink, Onboarding, charts |
| Light / dark | WINDOWS rows 4 and 6 | audit with `XCUIDevice.appearance` | observe |
| Increase Contrast | WINDOWS row 4 (C14-7 contrast audit over History in light, dark and Increase Contrast) | audit `.contrast` with `simctl ui ... increase_contrast enabled` | observe |
| VoiceOver actions rotor on a History row (Duplicate/Delete) | WINDOWS row 3 (C14-2) | `ShellNavigationUITests` VoiceOver test covers Cancel only | optional; list only |

The 05-UAT also records that test 9 (callout date format) was automated-only and never human-confirmed; mention it, do not change it.

### Observations the human check should specifically target (found by read, not run)
- Animations not gated by `accessibilityReduceMotion` [VERIFIED by grep, lines quoted]: `DPArcProgress.swift:18` `.animation(hasSettledOnce ? .easeOut(duration: 0.4) : nil, value: pct)`; `ConsumptionOverviewCard.swift:110` `.animation(hasSettledOnce ? .easeOut(duration: 0.5) : nil, value: pctClamped)`; `HistoryCalendarView.swift:61` `.animation(.easeInOut(duration: 0.25), value: selectedDay)`. UI-C-08's retain audit listed History, EventContextMenu, both charts and Onboarding only. `DPArcProgress` WR-02 (deferred, in `2026-11-13-triage-deferred-phase-09-review-findings.md`) already says the Reduce Motion check is missing there, and WR-01 says `ArcShape` never interpolates, so the arc may not actually move. If the human check shows motion with Reduce Motion on, that is a new finding: record it, route it to a D-09 brief (accessibility is a D-09 trigger per `08-DECISION-REGISTER.md` "Independent-outcome rule"), do not fix it inside Phase 11.
- Fixed chart height: `AlcoholAreaChart.swift:~79` `.frame(height: 100)` with `.font(.caption2)` axis labels. AX5 could clip axis labels; a watch point, not a claimed defect.

### Isolation for the human checklist
Use a cloned simulator (`xcrun simctl clone <device> <new name>` [VERIFIED: simctl help]) and delete it afterwards, as Phase 10 did for its dry run. Reset text size, appearance, Increase Contrast, Reduce Motion and VoiceOver before any later automated run. Run the checklist after the automated full suite or on the clone.

## SC5: Substantial Discoveries and Their Recorded Outcomes

ID namespace collision (record it, do not fix it): `08-INVENTORY.md` uses C001-C021 for inventory candidates, while `08-DECISION-REGISTER.md` uses C001-C013 for owner decisions. They differ. For example inventory C004 is decision brief C002 (`08-INVENTORY.md:63`: "| C004 | [UI-C-04] ... | **yes**, [brief](08-DECISION-C002.md)"), inventory C008 is brief C005, inventory C010 is brief C007, inventory C011/C012 are briefs C008/C009, inventory C016-C018 are briefs C010-C012. CONTEXT's "C001 to C013" means the register IDs. Briefs carry a frozen header "owner-approved eligibility recorded — modernization not started" (all of C001-C012); that is a Phase 08 record state, not the outcome. Outcomes live in the Phase 09/10 documents below.

| ID (register) | Subject | Recorded outcome and location | Gap flag |
|---------------|---------|-------------------------------|----------|
| C001 | Add Drink dismissal warning | Change, done by plan 09-02: `09-RETAIN-EVIDENCE.md` index row "UI-C-01 | Change | Completed by Plan 09-02"; `09-ADD-DRINK-EVIDENCE.md` | none |
| C002 | History list/calendar audit | Retain: index row UI-C-04; section "UI-C-04 / UI-C-05" (line 97) | none |
| C003 | History context menu | Retain: UI-C-05, same section | none |
| C004 | Charts interaction/accessibility | Retain, "pass for automated scope" (section line 103); human Audio Graph check deferred to Phase 11 | open until VER-03 |
| C005 | Reduce Motion | Retain; "requires human runtime verification before any change" (index row UI-C-08); brief `08-DECISION-C005.md`: "Phase 11 verifies" | open until VER-03; see ungated-animation observation |
| C006 | Liquid Glass | Retain (UI-C-09) plus C013 follow-up; owner acceptance statement `09-FLASH-DIAGNOSIS.md` "Decision C006 acceptance statement" (line 345) | D1 deferred (not fixed) |
| C007 | VoiceOver UI test | Change, done by 09-02 and rewritten by 09-05 (`ShellNavigationUITests`) | none |
| C008 | Schema/migration boundary | `10-EVIDENCE.md` "C008 disposition": "Disposition: retain." | none |
| C009 | Backup export/import | `10-EVIDENCE.md` "C009 disposition": "Disposition: retain (importer and format unchanged)." | none |
| C010 | Notification concurrency | `10-CONCURRENCY-RECORD.md` C010: "Disposition: applied narrow fix." (owner decision `fix-service-epoch+handler-sendable`, F3) | none |
| C011 | HealthKit concurrency | `10-CONCURRENCY-RECORD.md` C011: "Disposition: applied narrow fix." (F2, `fix-query-first`) | none |
| C012 | Async cleanup/cancellation | `10-CONCURRENCY-RECORD.md` C012: "Disposition: retain." | none |
| C013 | Dashboard `GlassEffectContainer` | `08-DECISION-REGISTER.md` row C013 (`revert-container-only`, 2026-11-13); `09-RETAIN-EVIDENCE.md` follow-up section (line 260); `09-FLASH-DIAGNOSIS.md` | none; fixes neither D1 symptom |
| Inventory C002 / UI-C-02 (no brief) | `DPArcProgress` compile error | Change, plan 09-01 (`09-RETAIN-EVIDENCE.md`: "Completed by Plan 09-01") | not in the register by design |
| Inventory UI-C-03, UI-C-07 (no brief) | stable identity, Observation owners | Retain, `09-RETAIN-EVIDENCE.md` index | not in the register by design |
| F2 | Health edit-then-delete orphan | `10-DECISION-F2.md`: "**Outcome:** fix-query-first" | none |
| F3 | Cancel-in-flight stale request | `10-DECISION-F3.md`: "**Outcome:** fix-service-epoch+handler-sendable" | none |
| F4 | Weekly summary copy | `10-DECISION-F4.md`: "**Outcome:** as-of-last-visit" | none |
| Device finding | Cold-launch tap | `10-DECISION-DEVICE-FINDING.md`: "**Outcome:** sync-assign"; re-test PASS in `10-DEVICE-RETEST.md` | weekly cold tap not observed (open-questions) |
| D1 | Flicker and simulator crash | Owner deferral; todo `2026-09-18-...`; `09-FLASH-DIAGNOSIS.md` | deferred, not fixed |

Discoveries without a decision brief the SC5 sentence ("all substantial modernization discoveries received a recorded analysis and discussion outcome") should also cover. The plan should confirm each has a recorded analysis and an explicit "deferred" or "accepted" outcome, and list any that lacks one as a gap rather than writing one: (a) Phase 10 WR-04 store recovery fires on any open error (open-questions "Store recovery fires on any ModelContainer open error": analysis recorded, product decision pending, outcome = deferred); (b) the Phase 10 R1-WR-01 Health update path and WR-02/WR-03 weekly-summary behavior changes (owner-accepted in UAT round 2, `STATE.md` decision line); (c) the production build-date/privacy-manifest question (open-questions, which itself says "Relevant to Phase 11 release verification"); (d) any new finding from the Phase 11 audit and human checklist. For (d), MOD-05 requires the same discussion route.

## Debt Ledger Inputs (list, never close)

| Source | Items | Note for the ledger |
|--------|-------|---------------------|
| D1 todo | `2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md` | Pending; flicker and crash not fixed, not device-confirmed. Open sub-items in open-questions: H1-H6, G1-G6, Feedback draft, device confirmation |
| Pending todos (8) | branch-per-milestone (tooling), History filtering, name autocomplete scope, `2026-09-15-migrate-project-to-ios-27...` (frontmatter `resolves_phase: 08` but still in `pending/`; stale record), D1, export-dismiss flake, history-edit tests, triage Phase 09 review findings (WR-01..WR-04, IN-01..IN-04) | `ls .planning/todos/pending` this session |
| WINDOWS.md (11 rows; frontmatter `open_count: 10`, `fixed_count: 1`, `last_updated: 2026-08-04T01:31:57.914Z`) | Open: 1 and 7 (Domain coverage, same gap), 2 (HistoryInteractionUITests over 300 lines: row says 319-324 lines, the file is now 225 lines plus extension files, so the row is probably stale; verify, do not close), 3 (C14-2 VoiceOver rotor), 4 (C14-7 contrast audit), 6 (B9-3 glass at AX5), 8 (B10-1), 9 (no UI regression for WR-01 section-cache), 10 (hardcoded English accessibility label), 11 (magic 20 g fallback). Fixed: 5 | Rows 3, 4, 6 overlap the VER-03 checklist. Run their checks only as part of the checklist if the owner wants; any status change needs the owner running `windows fixed`/`waive` with evidence. `/gsd-ship` blocks while `open_count > 0` (ledger header). |
| `.claude/context/open-questions.md` (14 entries) | production build date and privacy manifest (no `PrivacyInfo.xcprivacy` found by the entry's own `find`); store recovery trigger; hero-card test; weekly natural delivery; debugger attach; D1; History edit tests; deferred Phase 09 review findings; BAC; multi-currency; guideline alert card tap; History swipe-to-delete; Watch transport; Domain coverage | list with owner |
| Verification record states | `08-VERIFICATION.md` frontmatter `status: passed`; `09-VERIFICATION.md` `status: gaps_found`, `score: 12/14`, `verified: 2026-11-12T21:55:00+01:00` (pre-09-10); `10-VERIFICATION.md` `status: passed` | CONTEXT calls 08 and 10 "stale"; their frontmatter reads `passed`. Record "as read" with the date and say staleness is relative to a covered-files digest that Phase 11 does not re-evaluate. Do not edit them. |
| Phase 10 residuals | R-01 interrupted migration, R-02 interrupted Health write (both `acknowledged` in `10-DEVICE-SESSION.md`), R-03 three cold taps finite sample, WR-04 | list |
| PROJECT.md tech debt | launch-icon real-hardware size quirk (owner accepted), `STATE.md` blocker "Accessibility audit (VoiceOver, Dynamic Type up to AX5) is still outstanding — not yet started" | the second is exactly VER-03 |

Living-doc contradictions to surface before planning (AGENTS.md: surface contradictions): `STATE.md` frontmatter says `current_phase: 09`, `status: verifying`, `completed_phases: 1`, body says "Phase 09 ... EXECUTING", while `ROADMAP.md` and `REQUIREMENTS.md` say Phase 09 is complete; `current-focus.md` says "next is the Phase 09 re-verification run, then Phase 11", which CONTEXT overrode (proceed without re-verification). The plan's doc-reconciliation task must cover all of these without rewriting history.

## Common Pitfalls

### Pitfall 1: Scheme skip entries are ignored
**What goes wrong:** D1 harness tests crash the simulator and take the run down.
**Why:** `shouldAutocreateTestPlan = "YES"`; `SkippedTests` in the scheme were ignored (commit `7631c4d` message).
**How to avoid:** rely on the env-var gate; never set `TEST_RUNNER_DP_RUN_FLASH_HARNESS`; assert in the evidence that both tests report Skipped.
**Warning signs:** a crash log or a stalled UI run near `SheetDismissTabSwitchUITests`.

### Pitfall 2: Incremental MCP build mistaken for warning evidence
**What goes wrong:** a 3 s "build succeeded" hides warnings in unrecompiled files.
**How to avoid:** use the clean CLI builds above; record why CLI.

### Pitfall 3: Simulator-global accessibility settings leak into automated runs
**What goes wrong:** Increase Contrast, text size or appearance left on changes layouts and fails unrelated UI tests (the hero-height test is already position sensitive).
**How to avoid:** cloned simulator for the checklist; reset after; automated full suite first.

### Pitfall 4: Audit issues turn the suite red
**What goes wrong:** a new audit test finds real contrast or clipping issues on existing screens, producing a "new failure" that CONTEXT defines as a blocker.
**How to avoid:** exploratory run first; every issue becomes a ledger entry with an id; the committed test allow-lists exactly those ids (visible, counted), so the suite is honest and green. Do not silently pass.

### Pitfall 5: Polish system locale
**What goes wrong:** any test or checklist step matching system UI by label fails.
**How to avoid:** AGENTS.md rule; the import-picker gap is partly this.

### Pitfall 6: Stale numbers from earlier phases
**What goes wrong:** quoting 94.61 percent or 214 events as current.
**How to avoid:** label every inherited number with its phase and date; re-measure coverage.

### Pitfall 7: VoiceOver left enabled
`ShellNavigationUITests` disables VoiceOver only pre-launch and in a teardown registered before `enable()`; copy that structure in any new test.

## Code Examples

### Audit test skeleton (new, test-only; place at `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift` to mirror AGENTS.md test layout)
```swift
// Signature verified in Xcode 27.2 SDK swiftinterface; body is a plan-level sketch [ASSUMED pattern].
import XCTest

@MainActor
final class AccessibilityAuditUITests: XCTestCase {
    // Ledger ids of audit issues already recorded in 11-EVIDENCE.md. Empty at first run.
    private let allowedIssueIDs: Set<String> = []

    func test_audit_dashboard_default() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-dp_onboarding_done", "YES", "-dp_uitest", "YES",
                                "-dp_uitest_dataset", "multiday"]
        app.launch()
        try app.performAccessibilityAudit(for: .all) { issue in
            // return true = issue handled (ignored). Allow only issues already in the ledger.
            return self.allowedIssueIDs.contains(issue.compactDescription)
        }
    }
}
```
Variants for AX5 add `"-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"` [pattern: HistoryDynamicTypeUITests.swift:23]; dark sets `XCUIDevice.shared.appearance = .dark` and restores it in a teardown block. Use element identifiers or the tab bar `app.tabBars.buttons["History"]` (the pattern used in existing tests), never localized system labels.

### simctl commands for the checklist clone
```bash
xcrun simctl clone "$UDID" "dp-phase11-a11y"
xcrun simctl ui "$CLONE" appearance dark
xcrun simctl ui "$CLONE" increase_contrast enabled
# reset
xcrun simctl ui "$CLONE" appearance light; xcrun simctl ui "$CLONE" increase_contrast disabled
xcrun simctl delete "$CLONE"
```

## State of the Art

| Old approach | Current approach | Impact |
|--------------|------------------|--------|
| Manual Accessibility Inspector audits | `performAccessibilityAudit(for:_:)` in UI tests (iOS 17+) [VERIFIED: header `API_AVAILABLE(... ios(17.0) ...)` on the audit type] | Automatable column |
| Disabling VoiceOver before UI tests | `XCUIDevice.voiceOverService` (iOS 27.0) | Real VoiceOver traversal in XCUITest, no rotor |
| Xcode scheme `SkippedTests` | Runtime `XCTSkipUnless` gates with env var | Scheme skips are ignored under auto-created test plans (this repo's evidence) |
| Simulator settings by hand | Xcode 27 Device Hub settings inspector (Appearance, Liquid Glass, Text Size) [CITED: Xcode, Configuring the environment of a simulated device] | Optional convenience; does not list Reduce Motion in the retrieved text |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Whether a human can enable VoiceOver and reach the Audio Graph rotor action on the iOS 27 simulator is unknown; Apple's article says VoiceOver is not available on Simulator, while XCUIVoiceOverService worked there | VER-03 | If unavailable, both Audio Graph items stay "open"; SC4 still met (open is allowed) |
| A2 | No scriptable Reduce Motion switch exists for simulators (only `appearance` and `increase_contrast` were read from `simctl ui` help; later options were not retained) | VER-03 | Low; a scriptable route would only change the "automated" column |
| A3 | A new test-only audit class is within Phase 11 scope ("No test or app fixes ... for the known non-green items" does not forbid it; CONTEXT lists "accessibility audits" as an automated column) | VER-03 | If not in scope, the automated audit column is empty and the checklist is human-only |
| A4 | A single-run flake that passes on isolated re-run may be recorded as a flake with both results, even if not on CONTEXT's list | VER-01 | If CONTEXT is read strictly, such a test is a blocker |
| A5 | CLI full run with coverage is an acceptable "named missing capability" under the MCP-first rule | VER-01 | Owner may require MCP-only and accept no coverage number |
| A6 | Import cannot be reliably UI-tested (system document picker) so recording a limitation is preferable to a new test | VER-02 | Owner may want a test; costs a flaky system-UI test |
| A7 | Fixed 100 pt `AlcoholAreaChart` frame may clip axis labels at AX5 | VER-03 | Only affects where the human looks |

## Open Questions (RESOLVED)

All seven questions are answered by owner or autonomous decisions in `11-CONTEXT.md`. Each line below names the deciding entry; where a later owner amendment changed the outcome, the amendment is named too.

1. **Simulator VoiceOver and Audio Graph (A1)**
   - Known: docs and repo disagree. Unclear: human rotor access. Recommendation: probe first in the checklist; accept "open".
   - RESOLVED: D11-03 (the owner runs the human checklist on the simulator; each item is pass, fail or explicitly open, so a VoiceOver or Audio Graph item that cannot be reached stays open) with D11-09 (the three skipped Phase 05 checks are folded into the checklist).
2. **Should the recorded device-proof limitation list all nine post-`a38a75f` production files, not only the Dashboard revert?**
   - Recommendation: yes; it is a fact from `git diff --stat`, and the data-safety claim is the point of VER-02.
   - RESOLVED: D11-14 (all nine production files changed after a38a75f are named one by one).
3. **Full-suite runner (A5).** Recommendation: one detached CLI run with coverage; MCP for scoped runs.
   - RESOLVED: D11-15 (yes, one detached CLI full run with `-enableCodeCoverage YES`), narrowed by the owner runner amendment D11-20 (Xcode MCP for every other build and test step; the CLI is allowed only for the one Release build and the one full-suite run with coverage).
4. **Flake protocol (A4).** Recommendation: re-run a failing non-listed test once in isolation; if it passes record "flake, not on list, both results", surface to the owner at the checkpoint instead of silently adding it.
   - RESOLVED: D11-16 (re-run once alone; pass means a newly observed flake with a new todo, a second failure is a blocker for the owner).
5. **Import coverage (A6).** Recommendation: limitation, no new test.
   - RESOLVED: D11-13 (recorded as a VER-02 limitation, backed by the importer unit tests and the Phase 10 device import round trip; no UI test drives the system picker).
6. **Ungated animations observation.** Recommendation: human check records; if it fails, write a D-09 brief (candidate C014) and defer the fix.
   - RESOLVED: D11-17 (each site goes on the VER-03 human checklist; a confirmed defect gets an owner D-09 brief), then amended by the owner decision D11-23 of 2026-11-16 (change C014, C015 and the CHK-04 site in the gap-closure plans; recorded in `11-CONTEXT.md` by plan 11-12).
7. **Privacy manifest question** (open-questions says relevant to Phase 11): recommendation: list in the ledger as open, no action, because it is not in MOD-04/VER-01..03.
   - RESOLVED: D11-18 (ledger entry only, not resolved in Phase 11).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | all | yes | 27.2 (27B52) | none needed |
| Xcode running with project open (MCP) | MCP runs | yes (workspace listed for `drinkpulse.xcodeproj`; a second workspace `MinimalRepro` is also open, so `workspaceIdentifier` is mandatory) | — | ask owner to open it |
| iOS 27.2 simulators (iPhone 17, 18 Pro, Air, 17e, ...) | tests, checklist | yes, shutdown | runtime 24B8117 and a second 27.2 variant | — |
| `xcresulttool get test-results`, `xccov`, `simctl ui/clone` | evidence | yes | Xcode 27.2 | — |
| Owner time for the human checklist | VER-03 | owner-dependent | — | items stay explicitly open |
| Physical iPhone | device checks | out of scope | — | deferred by CONTEXT |

**Missing with no fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Test`, `#expect`) for unit; XCTest/XCUITest for UI; Xcode 27.2 |
| Config file | `drinkpulse.xcodeproj/xcshareddata/xcschemes/drinkpulse.xcscheme` (auto-created test plan; both testables `skipped = "NO"`) |
| Quick run command | Xcode MCP `RunSomeTests` with `targetName` + `testIdentifier`; CLI equivalent `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$UDID" -only-testing:drinkpulseUITests/<Class>` |
| Full suite command | the detached CLI command under "Pattern 1" (about 30 minutes) |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MOD-04 | 0 app-owned warnings, Debug and Release | build scan | clean builds + `grep -cE '(\.swift:[0-9]+:[0-9]+: \|ld: \|clang: )warning:'` == 0 | n/a (log gate) |
| VER-01 | suites pass except named exceptions | unit + UI | full run + `xcresulttool get test-results summary` mapped to the exception table | yes |
| VER-02 onboarding, startup/retry, add, delete, History, Insights, settings, export | flow completes | UI | `-only-testing:` the classes in the VER-02 table | yes |
| VER-02 edit | edit persists | UI | `EditVolumeIntegrityUITests`, `DuplicateEditPersistenceUITests` | yes (two others red, listed) |
| VER-02 import | round trip, no loss | unit + device record | `DataImporterRoundTripTests`, `ComprehensiveRoundTripTests`, `SanitizedBackupFixtureTests` | yes; no UI test (limitation) |
| VER-02 data preserved | stored data survives migration | unit | `MigrationChainV1Tests`, `MigrationChainV2V3Tests`, `MigrationSweepTests`, `StoreBootstrapTests` | yes |
| VER-03 audit | no unrecorded audit issue per tab, default/AX5/dark | UI | `-only-testing:drinkpulseUITests/AccessibilityAuditUITests` | no, Wave 0 (conditional on A3) |
| VER-03 AX5 | History row | UI | `HistoryDynamicTypeUITests` | yes |
| VER-03 VoiceOver | Cancel under VoiceOver | UI | `ShellNavigationUITests/test_withVoiceOverRunning_...` | yes |
| VER-03 descriptors | chart AX content | unit | `AlcoholAreaChartAXDescriptorTests`, `WeekdayBarChartAXDescriptorTests` | yes |
| VER-03 Audio Graph action, Reduce Motion, Increase Contrast, visual dark/light | human only | manual | `11-A11Y-CHECKLIST.md` | Wave 0 (document) |

### Sampling Rate
- **Per task commit:** MCP `RunSomeTests` for the touched or newly added class only (docs-only tasks: none).
- **Per wave merge:** all VER-02 classes via MCP `RunSomeTests`.
- **Phase gate:** one full CLI suite with coverage; every failure mapped; `git status` clean of source changes except any new test file; 300-line check (`find drinkpulse -name "*.swift" ... | xargs wc -l | awk '$1 > 300 {print}'`).

### Wave 0 Gaps
- [ ] `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift` (conditional on A3)
- [ ] `11-A11Y-CHECKLIST.md` (owner checklist with probe step and per-item automated/human columns)
- [ ] `11-EVIDENCE.md` skeleton with the evidence fields above
- [ ] out-of-git log directory `~/Library/Logs/DrinkPulse/phase-11-ios27/<UTC stamp>`

## Security Domain

`security_enforcement` is enabled (ASVS level 1). The phase adds no runtime code paths (at most one UI test file), so almost all categories are not applicable; the controls that matter are about evidence handling.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2/V3/V4 (auth, session, access) | no | no accounts, no backend |
| V5 Input Validation | no | no new input handling |
| V6 Cryptography | no | none added |
| V8 Data Protection / privacy | yes (evidence handling) | no health values, identifiers, or raw logs in git; counts, PASS/FAIL and timings only (`10-DEVICE-SESSION.md` "Privacy rule"); raw logs outside the repo; do not commit simulator UDIDs |

| Threat pattern | STRIDE | Mitigation |
|----------------|--------|------------|
| Health data or backup contents leaking into committed evidence | Information disclosure | counts only; sanitized fixtures only; never attach export files |
| New dependency or network call introduced "for testing" | Tampering | none planned; AGENTS.md forbids |

## Project Constraints (from CLAUDE.md / AGENTS.md)

- Apple documentation first via Xcode MCP `DocumentationSearch` (used this session: `performAccessibilityAudit`, Audio Graph, `XCUIVoiceOverService`, `XCUIDevice.appearance`, accessibility testing, simulator environment). Record official source, availability, rationale for every Apple API change (none here).
- Xcode MCP for builds/tests; call `XcodeListWorkspaces`, pass `workspaceIdentifier`; CLI only for a named missing capability (clean build, Release, coverage) or in a worktree.
- Zero warnings, scoped-then-full tests; full suite required at milestone close; coverage at least 90 percent overall.
- UI tests required for user-facing features (no feature changes here, so the import and edit gaps are recorded limitations, not new features).
- English-only docs; no AI attribution in commit messages beyond what the session reminder dictates; never push.
- Living docs reconcile with reality in the same task: README.md, PROJECT.md, ROADMAP.md, REQUIREMENTS.md (MOD-04, VER-01..03), current-focus.md, open-questions.md, DEVLOG (append-only), STATE.md.
- Locale independence: simulator system locale is Polish.
- 300-line file ceiling (a new audit test must stay well under it).
- Append-only and frozen documents (`DEVLOG.md`, plan files, ADRs): append only.

## Sources

### Primary (HIGH confidence, read or measured this session)
- `.planning/phases/11-.../11-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md` (Phase 11 section)
- `08-BASELINE.md`, `08-DECISION-REGISTER.md`, `08-INVENTORY.md` (lines 43-89), `08-INVENTORY-UI.md` (UI-test evidence handoff)
- `09-UAT.md`, `09-RETAIN-EVIDENCE.md` (index lines 17-33), `09-05-SUMMARY.md`, `09-03-SUMMARY.md`, `09-VERIFICATION.md` (frontmatter)
- `10-EVIDENCE.md`, `10-DEVICE-SESSION.md`, `10-DECISION-F2/F3/F4.md`, `10-DECISION-DEVICE-FINDING.md`, `10-CONCURRENCY-RECORD.md`
- `milestones/v1.3-phases/05-insights-chart-scrubbing/05-UAT.md`, `.claude/context/open-questions.md`, `.claude/context/current-focus.md`, `.planning/WINDOWS.md`, `.planning/todos/pending/*`
- Source/test reads: `DataSection.swift`, `HistoryDynamicTypeUITests.swift`, `ShellNavigationUITests.swift`, `SheetDismissTabSwitchUITests.swift:66-80`, `AlcoholAreaChart(+Accessibility).swift`, `WeekdayBarChart+Accessibility.swift`, `drinkpulse.xcscheme`, UI-test inventory by `grep func test_` over `drinkpulseUITests`
- Commands run: `xcodebuild -version`, `swift --version`, `xcrun simctl list`, clean Debug and Release builds, `git diff --stat a38a75f HEAD`, Xcode MCP `BuildProject`
- Xcode 27.2 SDK: `XCUIAutomation.framework` swiftinterface line 14, `XCUIAccessibilityAuditTypes.h`, `XCUIDevice.h:67`

### Secondary (MEDIUM confidence, Apple docs via Xcode MCP DocumentationSearch)
- Accessibility: "Performing accessibility audits for your app: Add audits to your UI tests"; "Performing accessibility testing for your app" (assistive technologies, settings, diagnose); "Representing chart data as an audio graph"; "Testing system accessibility features in your app"
- XCUIAutomation: `XCUIAccessibilityAuditType`, `XCUIVoiceOverService` methods, `XCUIDevice.appearance`
- Xcode: "Diagnosing issues in the appearance of a running app" (Environment Overrides), "Configuring the environment of a simulated device" (Device Hub)

### Tertiary (LOW confidence)
- None used. `gsd_run query research-plan` seam not used: no external web research was needed and all providers in `config.json` are disabled.

## Metadata

**Confidence breakdown:**
- Warning inventory: HIGH - measured with clean builds this session (one machine, scratch derived data)
- Test and flow map: HIGH - read from files; pass/fail not re-run in this session
- Accessibility automation: MEDIUM - API facts verified in the SDK; simulator VoiceOver behavior unresolved (A1)
- SC5 and ledger: HIGH for what exists, MEDIUM for "stale" verification states (frontmatter read, digest not recomputed)

**Research date:** 2026-11-14
**Valid until:** 2026-11-21 (HEAD `0c1cc19`; any new production commit invalidates the warning inventory and the 9-file limitation list)
