---
phase: 08-ios-27-baseline-api-inventory
verified: 2026-11-12T15:58:09Z
status: human_needed
score: 22/23 must-haves verified (1 WARNING); 0 behavior-unverified; 8 judgment-tier prohibitions flagged for human review
covered_files:
  - ".claude/context/current-focus.md"
  - ".planning/PROJECT.md"
  - ".planning/REQUIREMENTS.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-01-PLAN.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-01-SUMMARY.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-02-PLAN.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-02-SUMMARY.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-03-PLAN.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-03-SUMMARY.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-04-PLAN.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-04-SUMMARY.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-05-PLAN.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-05-SUMMARY.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-06-PLAN.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-06-SUMMARY.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-07-PLAN.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-07-SUMMARY.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-08-PLAN.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-08-SUMMARY.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.json"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C001.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C002.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C003.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C004.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C005.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C006.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C007.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C008.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C009.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C010.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C011.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C012.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-REGISTER.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-DOC-AUDIT.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-DATA.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY.md"
  - ".planning/phases/08-ios-27-baseline-api-inventory/08-UAT.md"
  - "AGENTS.md"
  - "CLAUDE.md"
  - "README.md"
  - "docs/architecture.md"
  - "drinkpulse.xcodeproj/project.pbxproj"
  - "drinkpulse/Domain/Persistence/MigrationPlan.swift"
  - "drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift"
  - "drinkpulse/Domain/Persistence/Schemas/SchemaV2.swift"
  - "drinkpulse/Domain/Persistence/Schemas/SchemaV3.swift"
  - "drinkpulse/Domain/Persistence/Schemas/SchemaV4.swift"
covered_digest: "v4:sha256:47d63dbb0faa1cb2433e8eb5343e2fde6649cbe1f70a99614c1fee9f55b1249e"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 14/14
  previous_verified: 2026-11-08T13:02:42Z
  reason: "Prior report went stale after covered files changed: d1760a7 (explicit IPHONEOS_DEPLOYMENT_TARGET = 27.0 on the app target in project.pbxproj), 4df1f96 (project.pbxproj: Debug-only Run Script phase; new AppVersionInfo Swift source), dd469d4 (current-focus.md, README.md one feature bullet), and 6581ca8 (validation re-audit). Every must-have that depends on those files was re-checked against current content."
  gaps_closed: []
  gaps_remaining: []
  regressions: []
  notes:
    - "project.pbxproj: d1760a7 adds explicit IPHONEOS_DEPLOYMENT_TARGET = 27.0 to the two app-target configurations. Effective settings are unchanged (27.0 inherited before, 27.0 explicit now). Re-checked with xcodebuild -showBuildSettings at HEAD and at d1760a7^ (archived copy): identical."
    - "Frozen schema snapshots (drinkpulse/Domain/Persistence/Schemas/*.swift) have no diff since fb6eba9."
    - "4df1f96 also added a Debug-only Run Script build phase (Embed Git Commit) and ENABLE_USER_SCRIPT_SANDBOXING = NO to project.pbxproj. Neither touches SWIFT_VERSION or IPHONEOS_DEPLOYMENT_TARGET; HEAD effective values are re-checked above. See Info I6."
    - "MigrationPlan.swift is unchanged since 2026-08-17; docs/architecture.md persistence topology matches it exactly."
    - "CLAUDE.md is now a one-line pointer to AGENTS.md (owner consolidation eb1b635, 2026-09-18). The simulator-destination section and baseline link live in AGENTS.md and README.md. Accepted as the relocation the 08-07 gap closure intended; see Truth 19."
    - "AGENTS.md added to covered_files: it is now the content source for the living simulator instructions."
    - "Prior report listed drinkpulse/Domain/Persistence/ as untouched since fb6eba9. This is no longer literally true: Phase 10 changed StoreBootstrap.swift (not a Phase 08 covered file). The Phase 08 prohibition is evaluated on Schemas/ and MigrationPlan.swift, which are unchanged."
gates:
  nyquist_validation: "re-audit run by orchestrator: 0 gaps (08-VALIDATION.md, committed 6581ca8)"
  security: "re-audit run by orchestrator: 22/22 threats closed, threats_open 0 (08-SECURITY.md)"
  code_review: "no new Phase 08 source since last review; 08-REVIEW.md remains clean (status clean, 0 findings)"
  ui_review: "skipped (no UI-SPEC, no UI code in phase)"
  regression: "skipped (first phase of milestone)"
human_verification:
  - test: "Decide the Polish-language prose policy for Phase 08 artifacts (WARNING W1)."
    expected: "Either translate the paraphrased fields to English (08-DECISION-REGISTER.md 'Exact scope' and 'Owner reason' columns for C001-C012; 08-INVENTORY.md handoff 'Approved scope' column, lines 136-147; the owner-response and scope blocks of 08-DECISION-C001..C012.md; the narrative of 08-06-SUMMARY.md) and keep the verbatim owner transcript as quoted source, or record an explicit acceptance of the Polish text under AGENTS.md 'Language: English only'."
    why_human: "Language policy exception for a historical-but-new artifact set is an owner decision; the owner decisions themselves are unambiguous."
  - test: "Decide whether AGENTS.md should carry the Xcode 27 / Swift 6.4 toolchain pin (WARNING W2 / Truth 4)."
    expected: "Either add one line to AGENTS.md 'Build & verify' or 'Local iOS 27 simulator destination' stating Xcode 27 (Swift 6.4 compiler, Swift 6 language mode), matching README.md line 119, or accept README.md plus docs/architecture.md as the sole toolchain pin."
    why_human: "The must-have requires the toolchain statement in all active setup/build/test docs; AGENTS.md (now the instruction source) has iOS 27 minimum and simulator steps but no Xcode/Swift pin. Whether that omission is acceptable is an owner call."
  - test: "Confirm the eight judgment-tier prohibitions below (non-authoritative LLM-judge verdicts)."
    expected: "Owner reads each verdict and its evidence and confirms, or opens a gap. Flag: unverified-prohibition - human review recommended."
    why_human: "Plan prohibitions carry flagged: true and status: unverified and have no verification: test tier. Per the verification rules they are judgment-tier. The LLM verdicts are recorded below and are not authoritative."
---

# Phase 08: iOS 27 Baseline & API Inventory Verification Report

**Phase Goal:** Establish a reproducible iOS 27 baseline and a complete, source-backed inventory before selecting code changes.
**Requirements:** PLAT-01, PLAT-02, MOD-01, MOD-05
**Verified:** 2026-11-12T15:58:09Z
**Status:** human_needed
**Re-verification:** Yes. The prior report (2026-11-08, passed 14/14) was stale after covered-file changes. Every must-have was re-checked against current content. Immutable evidence (08-BASELINE.md/json, dated inventory snapshots, decision briefs) was judged against the Phase 08 snapshot, not later state.

## Goal Achievement

### Observable Truths

Truths are the `must_haves.truths` of the eight plans (23 total). The five ROADMAP success criteria are cross-referenced below.

| #  | Truth (plan) | Status | Evidence |
| -- | ------------ | ------ | -------- |
| 1  | All app, unit-test and UI-test Debug and Release targets are iOS 27.0 with Swift 6.0 (01) | ✓ VERIFIED | Fresh `xcodebuild -project drinkpulse.xcodeproj -target <t> -configuration {Debug,Release} -showBuildSettings` at HEAD: `drinkpulse`, `drinkpulseTests`, `drinkpulseUITests` all `IPHONEOS_DEPLOYMENT_TARGET = 27.0`, `SWIFT_VERSION = 6.0`, in both configurations. Xcode 27.2 (27B52) on this host. Same values at `d1760a7^`. |
| 2  | Recorded Debug build, Release build and unfiltered full test, pass or fail (01) | ✓ VERIFIED | `08-BASELINE.json` runs: dependency resolution exit 0 (passed); Debug build exit 65 (failed); Release build exit 65 (failed); full test exit 65 (failed). Full-test command has no `-only-testing` or `-skip-testing`. Simulator `1D35E1B8-...` (iPhone 18 Pro, iOS 27.0 24A434) and toolchain Xcode 27.0 (27A266a), Swift 6.4 recorded. Failed runs are not represented as passes. |
| 3  | Every baseline diagnostic preserved and attributed (01) | ✓ VERIFIED | Raw logs at `/Users/fempter/Library/Logs/DrinkPulse/phase-08-ios27/20260916T200000Z` contain `DPArcProgress.swift:33:26` error (debug-build.stdout.log:418, release-build.stdout.log:518/553, full-test.stdout.log:376/471) and `AddDrinkView.swift:5:30` warning (debug:436, release:536/571, full-test:294). |
| 4  | Raw evidence referenced by relative path and SHA-256, complete (01) | ✓ VERIFIED | Re-hashed: 8 of 8 stdout/stderr streams exist and match their recorded SHA-256; the three `.xcresult` bundles exist. `git ls-files` contains 0 `.log` or `.xcresult` paths. |
| 5  | Every scoped tracked path has a candidate or no-candidate disposition (03, 04, 05) | ✓ VERIFIED | At the Phase 08 snapshot (`5572753`), 254 tracked paths under `drinkpulse/`, `drinkpulseTests/`, `drinkpulseUITests/`, `drinkpulse.xcodeproj/`; 0 unmentioned in `08-INVENTORY-UI.md`, `08-INVENTORY-DATA.md`, `08-INVENTORY.md`. No path deleted since. NC-UI-01..11 no-candidate rows present, plus N-D01-06, N-S01-04 and NC-TEST-01 in the data and master inventories. |
| 6  | UI and data API leads carry exact `path:line`, availability evidence and disposition (03, 04) | ✓ VERIFIED | 54 distinct `path:line` references (brace groups included) resolve against the Phase 08 snapshot tree: 0 missing files, 0 beyond EOF. Spot checks: `DPArcProgress.swift:33` is `private struct ArcShape: Shape`; `AddDrinkView.swift:5` is `@Entry var dismissSheet`; `HistoryListQueryView.swift:39` is `List {`. |
| 7  | Living build/test instructions reproduce the baseline on another Mac (02, 07) | ✓ VERIFIED | `README.md` lines 118-138 and `AGENTS.md` lines 432-446 and 548-562 define `xcrun simctl list devices available`, `export LOCAL_IOS_27_UDID=...`, `xcrun simctl bootstatus "$LOCAL_IOS_27_UDID" -b`, and link `08-BASELINE.md`. All six `-destination` uses in README and AGENTS use `id=$LOCAL_IOS_27_UDID`. No hard-coded UDID in any active doc (UUID grep over README, AGENTS, CLAUDE, current-focus, docs/*.md, .planning/PROJECT.md, REQUIREMENTS.md: 0 hits). |
| 8  | Active docs describe the selected toolchain and target consistently (02) | ⚠️ WARNING (see W2) | README line 119 "Requires Xcode 27 (Swift 6.4 compiler in Swift 6 language mode)"; README line 6 and AGENTS line 22 state iOS 27.0 minimum; docs/architecture.md line 5-8 states iOS 27.0 and links the Xcode 27/Swift 6.4 baseline. AGENTS.md (the agent instruction source and the build/test instruction doc after consolidation) states iOS 27 and simulator steps but contains no Xcode 27 or Swift 6.4 pin. No doc names an older compiler or simulator as current. |
| 9  | Present-tense project and focus descriptions agree with the Phase 08 target change; dated history stays dated (02) | ✓ VERIFIED | `.planning/PROJECT.md` line 154 and line 252 (iOS27-BASE validated in Phase 08). `.claude/context/current-focus.md` labels the Phase 08 section "Historical" and its iPhone 17 Pro / iPhone 18 Pro notes as historical. Info I1 below. |
| 10 | History List/ScrollView and context-menu workarounds retained until evidence (03) | ✓ VERIFIED | `08-INVENTORY-UI.md` UI-C-04 (`HistoryListQueryView.swift:39-81`) and UI-C-05 (`EventContextMenu.swift:5-58`): Retain, with a reconsideration gate. |
| 11 | Swift 6.4 language, standard-library, concurrency and testing opportunities checked against real call sites (04) | ✓ VERIFIED | `08-INVENTORY-DATA.md` contains 11 "Swift 6.4" references tied to call sites, with retain decisions where no benefit is shown. |
| 12 | Frozen schemas, identity, HealthKit, notification and transfer behavior untouched; substantial proposals decision-gated (04) | ✓ VERIFIED | `git diff --name-only 5287541^ 5572753 -- '*.swift'` returns 0 files. `drinkpulse/Domain/Persistence/Schemas/` has no diff since `fb6eba9`. C008-C012 cover schema, backup, notification, HealthKit and cleanup, each gated. |
| 13 | Master inventory accounts for every file, candidate, no-candidate row and baseline diagnostic (05) | ✓ VERIFIED | `08-INVENTORY.md` sections: Evidence boundary, Area and no-candidate index, candidate crosswalk, baseline diagnostic and test-result crosswalk, Swift 6.4 coverage, flagged assumptions, decision-gate rule, approved-only handoff. Failed runs listed as unavailable, not zero. |
| 14 | Each substantial candidate has its own source-backed brief and register row (05) | ✓ VERIFIED | `08-DECISION-C001.md` through `C012.md` exist, each with current behavior, decision table, availability and recommendation sections. `08-DECISION-REGISTER.md` links all twelve. |
| 15 | No substantial replacement authorized by a recommendation alone; only approved scope eligible (05) | ✓ VERIFIED | Register rows C001-C012 each carry `approve`, date 2026-09-16, exact scope and reason. Handoff in `08-INVENTORY.md` mirrors those twelve scopes. |
| 16 | Owner can inspect each brief before choosing approve, retain or defer (06) | ✓ VERIFIED | Briefs exist as separate files. `08-UAT.md` (complete, 1/1 pass, 2026-09-18) confirms the owner-decision provenance. |
| 17 | Every substantial candidate has a recorded owner outcome; only approved scope eligible for Phase 09/10 (06) | ✓ VERIFIED | Twelve explicit `approve` outcomes in the register. Handoff includes approved substantial scope only. |
| 18 | Later-discovered substantial candidates trigger the same brief and discussion gate (06) | ✓ VERIFIED | Rule text in `08-DECISION-REGISTER.md` line 35 and `08-INVENTORY.md` line 155; owner rule in `.planning/PROJECT.md` line 156. |
| 19 | A developer on another Mac can identify a local iOS 27 simulator and use it for documented commands (07) | ✓ VERIFIED | Same evidence as Truth 7. |
| 20 | README.md and CLAUDE.md identify the baseline as immutable evidence, not a general destination (07) | ✓ VERIFIED (relocated) | README.md lines 121-123 state the baseline identity is evidence, not a general destination. CLAUDE.md is now a pointer to AGENTS.md, which carries the same statement (AGENTS.md lines 442-446). The literal CLAUDE.md link no longer exists. This is the owner's consolidation (`eb1b635`), and CLAUDE.md states "All project instructions live in AGENTS.md." Accepted as the intended relocation. Recorded here so it is visible. |
| 21 | Every current general build, full-test, scoped-test and coverage command in the living entry points uses the local variable (07) | ✓ VERIFIED | README.md 133, 138. AGENTS.md 454, 550, 555, 560. CLAUDE.md contains no commands (pointer). No second destination form remains. |
| 22 | `docs/architecture.md` migration topology matches `MigrationPlan.swift` (08) | ✓ VERIFIED | `MigrationPlan.swift` lines 6-14: `schemas = [SchemaV1, SchemaV2, SchemaV3, SchemaV4]`, `stages = [v1ToV2, v2ToV3, v3ToV4]`. `docs/architecture.md` lines 124-150 list the same. |
| 23 | Guide marks V1-V3 frozen and V4 live; the next divergence freezes V4, adds SchemaV5 and a `v4ToV5` stage (08) | ✓ VERIFIED | `docs/architecture.md` "Snapshot-on-divergence rule" states the rule verbatim. `Schemas/SchemaV1-4.swift` have no diff since `fb6eba9`. |

**Score:** 22/23 truths verified; 1 WARNING (Truth 8). 0 behavior-unverified.

### Roadmap Success Criteria (contract)

| # | Success criterion | Status | Evidence |
| - | ----------------- | ------ | -------- |
| SC1 | iOS 27.0 minimum for app and both test targets in every configuration; SDK, runtime and dependency versions recorded | ✓ VERIFIED | Truth 1; `08-BASELINE.md` records SDK 27.0 and runtime iOS 27.0 (24A434); dependency resolution exit 0 with no resolved source packages. |
| SC2 | Debug and Release diagnostics captured with exact location and availability | ✓ VERIFIED | Truth 3. The baseline contains compiler errors and warnings, not deprecation diagnostics; no deprecation is claimed. |
| SC3 | Every production and test area reviewed; candidates recorded as change, retain or externally blocked, with no-change entries | ✓ VERIFIED | Truths 5, 6, 10. |
| SC4 | Build instructions and living platform docs reflect toolchain and target; baseline result and blockers recorded | ⚠️ WARNING | Truths 4-8. Living docs reflect iOS 27.0 and portable simulator steps. The Xcode 27 / Swift 6.4 pin is absent from AGENTS.md (W2). |
| SC5 | Substantial candidates have reviewable briefs; owner discusses scope before execution planning | ✓ VERIFIED | Truths 14-18. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `drinkpulse.xcodeproj/project.pbxproj` | Six iOS 27 / Swift 6 effective settings | ✓ VERIFIED | Lines 307-549 contain explicit 27.0 and 6.0 values; effective values unchanged by d1760a7. |
| `08-BASELINE.md` + `08-BASELINE.json` | Reproducible, truthful, immutable baseline | ✓ VERIFIED | 8/8 stream hashes match; three bundles exist; exit codes match the narrative. Judged against the capture, not later state. |
| `README.md` | Portable local destination and baseline link | ✓ VERIFIED | Lines 118-138. |
| `AGENTS.md` | Portable destination, baseline link, build commands | ✓ VERIFIED | Lines 432-446 and 548-562. Toolchain pin absent (W2). |
| `CLAUDE.md` | Pointer to the instruction source | ✓ VERIFIED | Single pointer to AGENTS.md (Truth 20). |
| `docs/architecture.md` | Source-aligned migration topology | ✓ VERIFIED | Matches `MigrationPlan.swift` exactly. Phase 10 recovery prose in the same section is outside Phase 08 scope (Info I4). |
| `drinkpulse/Domain/Persistence/Schemas/SchemaV1-4.swift` | Frozen snapshots (prohibition) | ✓ VERIFIED | No diff since `fb6eba9`. |
| `08-INVENTORY-UI.md`, `08-INVENTORY-DATA.md`, `08-INVENTORY.md` | Complete dated inventory | ✓ VERIFIED | Truths 5, 6, 10-13. Judged against the Phase 08 snapshot. |
| `08-DECISION-REGISTER.md` + `C001`-`C012` | Separate owner outcomes and briefs | ✓ VERIFIED | Truths 14-17. Polish prose: W1. |
| `08-DOC-AUDIT.md` | Active-doc audit | ✓ VERIFIED | Present. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| Baseline manifest | Project, scheme, configuration, simulator | Exact `xcodebuild` commands | ✓ WIRED | Project, scheme, Debug configuration and UDID agree across `commands` and `simulator`. |
| Baseline manifest | Raw evidence | Relative paths and SHA-256 | ✓ WIRED | 8/8 hashes match. |
| README.md, AGENTS.md | `08-BASELINE.md` | Immutable link | ✓ WIRED | Both links resolve. |
| `CLAUDE.md` | `AGENTS.md` | Pointer | ✓ WIRED | Relocated link chain (Truth 20). |
| `docs/architecture.md` | `08-BASELINE.md` | Link | ✓ WIRED | Resolves. |
| `current-focus.md` | `08-BASELINE.md`, `09-RETAIN-EVIDENCE.md` | Relative links | ✓ WIRED | Both targets exist. |
| `docs/architecture.md` | `MigrationPlan.swift` | Schema/stage topology | ✓ WIRED | Exact match. |
| Inventory candidates | Source `path:line` | Snapshot tree | ✓ WIRED | 54/54 resolve at `5572753`. |
| Candidates | Briefs, register, handoff | C001-C012 IDs | ✓ WIRED | 12 briefs, 12 register rows, 12 handoff rows. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
| -------- | ---- | ------ | ------------------ | ------ |
| Settings matrix | Effective target settings | `xcodebuild -showBuildSettings` on the live project, re-run this pass | Yes | ✓ FLOWING |
| Baseline JSON | Runs, hashes, diagnostics | External logs and `.xcresult` bundles | Yes, hash-validated | ✓ FLOWING |
| Inventory | Path coverage | Snapshot `git ls-tree 5572753` | 254/254 | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Effective target settings at HEAD | `xcodebuild -target {drinkpulse,drinkpulseTests,drinkpulseUITests} -configuration {Debug,Release} -showBuildSettings` | 27.0 / 6.0 for all targets, both configurations | ✓ PASS |
| Effective settings unchanged by d1760a7 | Same command on `git archive d1760a7^` copy | Identical values | ✓ PASS |
| Baseline stream integrity | Python: hash the 8 streams under `artifact_root`; check 3 bundles | 8 match, 0 missing, 0 mismatched; 3 bundles present | ✓ PASS |
| Diagnostic attribution | `grep` for `DPArcProgress.swift:33` and `AddDrinkView.swift:5` in raw stdout logs | Present at the recorded lines | ✓ PASS |
| Inventory path coverage at snapshot | Python: `git ls-tree 5572753` scoped paths vs inventory text | 254 scoped, 0 unmentioned | ✓ PASS |
| Inventory location resolution at snapshot | Python: parse 54 `path:line` refs against `5572753` | 0 missing, 0 beyond EOF | ✓ PASS |
| Full app test suite | Not run | Baseline already fails before tests start; a full run is out of scope for this documentation re-verification | ? SKIP |

### Probe Execution

No Phase 08 probe declared; no conventional `scripts/**/tests/probe-*.sh` for this phase. SKIPPED.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| ----------- | ------------ | ----------- | ------ | -------- |
| PLAT-01 | 08-01 | All app and test targets require iOS 27.0 in every relevant configuration | ✓ SATISFIED | Truth 1; `REQUIREMENTS.md` line 12 `[x]`, traceability line 52 Complete. |
| PLAT-02 | 08-01, 08-02, 08-05, 08-07 | Documented toolchain; scripts, dependencies and living docs match baseline | ✓ SATISFIED (with W2) | Truths 2, 4 (WARNING), 7, 19-21; `REQUIREMENTS.md` line 13 `[x]`, line 53 Complete. |
| MOD-01 | 08-03, 08-04, 08-05, 08-08 | Complete source-backed candidate and no-candidate inventory | ✓ SATISFIED | Truths 5, 6, 10, 11, 13, 22, 23; `REQUIREMENTS.md` line 17 `[x]`, line 54 Complete. |
| MOD-05 | 08-03, 08-04, 08-05, 08-06 | Owner can review concrete substantial-replacement analysis before execution scope | ✓ SATISFIED | Truths 14-18; `REQUIREMENTS.md` line 21 `[x]`, line 55 Complete. |

**Orphan check:** `REQUIREMENTS.md` traceability maps only PLAT-01, PLAT-02, MOD-01 and MOD-05 to Phase 08. All four appear in plan `requirements:` fields. Every plan requirement ID maps to one of these four. No orphaned and no unaccounted requirement IDs. MOD-02 and MOD-04 are mapped to Phases 09 and 11 and are out of scope here.

### Decision Coverage

Not re-run in this pass beyond Truths 14-18, which cover the decision-bearing artifacts (register, briefs, handoff, owner UAT).

## Prohibition Checks

The plan `must_haves.prohibitions` carry `flagged: true` and `status: unverified` and have no `verification:` field, so each is treated as judgment-tier. Verdicts below are non-authoritative LLM-judge verdicts with the flag `unverified-prohibition - human review recommended`. None is silently passed. Each is listed under Human Verification.

| # | Plan | Prohibition | LLM verdict (non-authoritative) | Evidence |
| - | ---- | ----------- | ------------------------------- | -------- |
| P1 | 08-01 | Raising the deployment minimum must not reset a SwiftData store or alter a shipped VersionedSchema snapshot | PASS (judgment) | Schemas unchanged since `fb6eba9`; d1760a7 effective-setting no-op; no `.swift` file changed in the Phase 08 window. |
| P2 | 08-01 | Committed baseline must not contain personal health values, signing secrets or bulky raw logs | PASS (judgment) | 0 tracked `.log` or `.xcresult`; grep for team IDs, provisioning, tokens and health terms in `08-BASELINE.*` clean. |
| P3 | 08-02 | Current docs must not imply an older compiler or simulator is the selected evidence environment | PASS (judgment) | README, AGENTS and architecture name Xcode 27 or iOS 27 as selected; iPhone 17 Pro appears only in historical sections and DEVLOG. |
| P4 | 08-03 | An API's age or an unverified skill lookup must not be presented as proof a change is beneficial | PASS (judgment) | UI-C-04 and UI-C-05 are Retain with explicit "no deprecation claim"; the inventory states "makes no unsupported deprecation claim". |
| P5 | 08-04 | Compiler or standard-library novelty must not justify a speculative rewrite of domain, migration, notification or HealthKit semantics | PASS (judgment) | No `.swift` change in the Phase 08 window; Domain, Persistence and Services rows are no-candidate or gated by C008-C011. |
| P6 | 08-05 | Final inventory must not hide a no-candidate area or imply a failed baseline passed | PASS (judgment) | NC rows present (N-D01-06, N-S01-04, NC-UI-01..11); failed runs listed as unavailable. |
| P7 | 08-05 | A substantial candidate must not enter a downstream plan merely because a brief exists | PASS (judgment) | Handoff and register include only `approve` rows; no `pending` row is treated as scope. |
| P8 | 08-06 | A missing response must not be recorded as owner approval | PASS (judgment) | Twelve explicit `approve` outcomes with date, scope and reason; `08-UAT.md` provenance pass (2026-09-18). |

## Warnings (non-blocking)

| # | Finding | Category | Disposition |
| - | ------- | -------- | ----------- |
| W1 | Polish-language prose remains in English-only documentation (AGENTS.md "Language: English only"): `08-DECISION-REGISTER.md` (12 rows, "Exact scope" and "Owner reason" columns), `08-INVENTORY.md` handoff "Approved scope" column (lines 136-147), owner-response and scope blocks in `08-DECISION-C001..C012.md`, and `08-06-SUMMARY.md` narrative. Unchanged since the prior report. | Documentation policy | WARNING. Does not defeat any must-have; owner decisions and bounds are unambiguous. Human decision in the HUMAN section. |
| W2 | AGENTS.md (active build and test instruction source) states iOS 27.0 and portable simulator steps but no Xcode 27 or Swift 6.4 toolchain pin. The pin is in README.md line 119 and the architecture overview. Under Truth 4 and SC4 this is a partial match. Not caused by covered-file drift: the pin was never in CLAUDE.md or AGENTS.md. | Documentation completeness | WARNING. Human decision in the HUMAN section. |

## Information (non-blocking)

| # | Finding | Disposition |
| - | ------- | ----------- |
| I1 | `.claude/context/current-focus.md` "Historical backlog" item 1 says "use the linked baseline as the only active build/test entry point". It sits in a section headed "Historical" and predates the 08-07 portable-destination fix, so it is dated history. It conflicts with README and AGENTS, which treat the baseline as evidence, not a destination. | Optional: reword to "the portable local destination flow, linked to the baseline as evidence". No status effect. |
| I2 | Host now runs Xcode 27.2 (27B52). The baseline pins Xcode 27.0 (27A266a). The baseline is immutable and was not re-captured. | None. Expected. |
| I3 | 26 tracked files under scoped directories were added after the Phase 08 snapshot (Phase 09, Phase 10 and quick task 261112-kvl, e.g. `Features/Settings/AppVersionInfo.swift`, `Services/Notification*Tests.swift`, `Domain/Persistence/Migration*Tests.swift`). The inventory is a dated snapshot. Not a Phase 08 gap. | None. A future inventory refresh would need to cover them. |
| I4 | Phase 10 changed `StoreBootstrap.swift` (not a Phase 08 covered file). The architecture recovery and rollback prose was updated by Phase 10 and was not re-verified here beyond the migration topology. | Out of Phase 08 scope. |
| I5 | `AGENTS.md` is added to `covered_files` in this pass. It is now the content source for the living simulator instructions. | None. |
| I6 | Commit `4df1f96` (quick-261112-kvl) added a Debug-only Run Script build phase, "Embed Git Commit (Debug)", and `ENABLE_USER_SCRIPT_SANDBOXING = NO` to `project.pbxproj`. It also added `Features/Settings/AppVersionInfo.swift` and a footer. The Phase 08 baseline commands are unchanged and still reproduce the recorded result class. The script is not in the captured baseline. A future re-capture should include it. PLAT-02's "build scripts match the baseline" is therefore only partly true of current HEAD. | Owner awareness. Not a Phase 08 must-have failure. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| Phase 08 docs and covered living docs | — | No unresolved `TBD`, `FIXME` or `XXX` marker | ℹ️ Info | No debt-marker blocker. |
| `08-DECISION-REGISTER.md`, `08-INVENTORY.md`, `08-DECISION-C*.md`, `08-06-SUMMARY.md` | multiple | Polish prose in English-only docs | ⚠️ Warning | See W1. |

## Human Verification Required

### 1. Polish prose policy for Phase 08 artifacts (W1)

**Test:** Decide whether to translate the paraphrased Polish fields listed in W1 to English (keeping the verbatim owner transcript as quoted source), or to accept the Polish text explicitly.
**Expected:** An owner decision recorded in writing.
**Why human:** Language-policy exception for a new artifact set is an owner decision.

### 2. Xcode 27 / Swift 6.4 pin in AGENTS.md (W2, Truth 4, SC4)

**Test:** Decide whether AGENTS.md needs a one-line toolchain pin (Xcode 27, Swift 6.4 compiler, Swift 6 language mode) matching README.md line 119.
**Expected:** Either the line is added, or README.md and the architecture overview are accepted as the sole pin.
**Why human:** The must-have requires the toolchain statement across all active setup/build/test docs; whether AGENTS.md needs it is an owner call.

### 3. Judgment-tier prohibitions P1-P8

**Test:** Review the LLM verdicts and evidence in the Prohibition Checks table and confirm each, or open a gap.
**Expected:** Owner confirms each verdict. Flag: `unverified-prohibition - human review recommended`.
**Why human:** Verdicts are non-authoritative. The plan prohibitions are flagged and have no test-tier enforcement.

## Gaps Summary

No BLOCKER. No FAILED truth, missing or stub artifact, or unwired key link. All four requirement IDs (PLAT-01, PLAT-02, MOD-01, MOD-05) are accounted for. Status is `human_needed` because two WARNINGs (W1, W2) and eight judgment-tier prohibition verdicts require a human decision. The covered-file drift (d1760a7 pbxproj lines, CLAUDE.md consolidation, current-focus.md, README, architecture) was re-checked; no effective setting, schema snapshot, migration topology or simulator instruction is contradicted. Immutable baseline evidence re-hashes cleanly.

---

_Verified: 2026-11-12T15:58:09Z_
_Verifier: Claude (gsd-verifier)_
