---
phase: 08-ios-27-baseline-api-inventory
verified: 2026-11-12T20:36:28Z
status: passed
score: 23/23 must-haves verified (1 via owner override); roadmap SC 5/5 (1 via owner override); 0 behavior-unverified; 0 gaps
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
covered_digest: "v4:sha256:5536afaf5acccc44e50c69494256d157d53bfa2ecc36fdf5bd831c76cb69b5ff"
behavior_unverified: 0
overrides_applied: 2
overrides:
  - must_have: "Developers encounter consistent current Xcode 27, Swift 6.4 compiler, Swift 6 mode, iOS 27 minimum and simulator instructions in all active setup/build/test docs"
    reason: "Owner decision: README.md line 119 and docs/architecture.md are accepted as the sole Xcode 27 / Swift 6.4 toolchain pin. AGENTS.md keeps the iOS 27 minimum and portable simulator steps but no toolchain pin. Recorded in 08-UAT.md test 2 (pass)."
    accepted_by: "owner"
    accepted_at: "2026-11-12T20:32:33Z"
  - must_have: "Project build instructions and living platform documentation reflect the selected toolchain and target"
    reason: "Same owner decision as the 08-02 toolchain-consistency override (README.md and docs/architecture.md as the sole toolchain pin). Roadmap SC4 is satisfied on the same basis. Recorded in 08-UAT.md test 2 (pass)."
    accepted_by: "owner"
    accepted_at: "2026-11-12T20:32:33Z"
re_verification:
  previous_status: human_needed
  previous_score: 22/23 (1 WARNING); 0 behavior-unverified; 8 judgment-tier prohibitions flagged
  previous_verified: 2026-11-12T15:58:09Z
  reason: "Prior report went stale only because 08-UAT.md (a covered file) changed in 2d1c365 (UAT complete, 3/3 pass). git diff 3d2d914..HEAD touches only 08-UAT.md; no codebase input changed since the 2026-11-12 15:58 pass. Recomputed covered_digest changed only because of the UAT content."
  gaps_closed: []
  gaps_remaining: []
  regressions: []
  notes:
    - "The three human-verification items from the prior report are resolved by the owner in 08-UAT.md (status complete, 3 passed, 0 issues): W1 Polish-language prose accepted; W2 toolchain pin accepted as README.md plus docs/architecture.md (recorded as override); P1-P8 judgment-tier prohibitions confirmed."
    - "Prior cross-reference error corrected: the toolchain-consistency truth is row 8 (08-02 plan truth 1), not 'Truth 4'. Row 4 is raw-evidence hashing and was never the warning."
    - "Regression spot-checks at HEAD 2d1c365 all pass: effective IPHONEOS_DEPLOYMENT_TARGET 27.0 and SWIFT_VERSION 6.0 for 3 targets x Debug/Release (xcodebuild -showBuildSettings); frozen schemas no diff since fb6eba9; zero Swift changes in 5287541^..5572753; zero tracked .log/.xcresult paths; 8/8 baseline stream SHA-256 match; MigrationPlan topology matches docs/architecture.md."
    - "Full app test suite not re-run at HEAD. The Phase 08 baseline is an immutable capture at the Phase 08 snapshot; re-running would exercise Phase 09/10 code and is outside this phase's scope. Recorded as SKIP in Behavioral Spot-Checks, not routed to human verification."
gates:
  nyquist_validation: "carried forward: 0 gaps (08-VALIDATION.md, committed 6581ca8); not a covered input of this pass"
  security: "carried forward: 22/22 threats closed, threats_open 0 (08-SECURITY.md); not a covered input of this pass"
  code_review: "carried forward: 08-REVIEW.md clean (status clean, 0 findings); no Phase 08 source changed since"
  ui_review: "skipped (no UI-SPEC, no UI code in phase)"
  regression: "run this pass: spot-checks listed in re_verification.notes all pass at HEAD 2d1c365"
  owner_accepted_warning: "W1 Polish-language prose in English-only documentation (AGENTS.md 'Language: English only'). Explicit owner acceptance, 08-UAT.md test 1 (pass). Not a must-have; recorded here and in the Warnings section."
  prohibitions: "P1-P8 judgment-tier verdicts (non-authoritative LLM-judge) confirmed by owner, 08-UAT.md test 3 (pass). Plan frontmatter status fields remain 'unverified'; this verifier did not edit plan files."
---

# Phase 08: iOS 27 Baseline & API Inventory Verification Report

**Phase Goal:** Establish a reproducible iOS 27 baseline and a complete, source-backed inventory before selecting code changes.
**Requirements:** PLAT-01, PLAT-02, MOD-01, MOD-05
**Verified:** 2026-11-12T20:36:28Z
**Status:** passed
**Re-verification:** Yes. Prior report (2026-11-12T15:58:09Z, human_needed, 22/23) went stale only because 08-UAT.md changed. The three human items are now resolved by the owner. Codebase inputs were unchanged since the prior pass, and regression spot-checks were run anyway.

## Goal Achievement

### Observable Truths

Truths are the `must_haves.truths` of the eight plans (23 total, counted from the plan files). The five ROADMAP success criteria are cross-referenced below.

| #  | Truth (plan) | Status | Evidence |
| -- | ------------ | ------ | -------- |
| 1  | All app, unit-test and UI-test Debug and Release targets are iOS 27.0 with Swift 6.0 (01) | ✓ VERIFIED | Re-checked this pass: `xcodebuild -target {drinkpulse, drinkpulseTests, drinkpulseUITests} -configuration {Debug, Release} -showBuildSettings` at HEAD 2d1c365 gives `IPHONEOS_DEPLOYMENT_TARGET = 27.0` and `SWIFT_VERSION = 6.0` for all six combinations. Host Xcode 27.2 (27B52). |
| 2  | Recorded Debug build, Release build and unfiltered full test, pass or fail (01) | ✓ VERIFIED | `08-BASELINE.json`: dependency resolution exit 0 (passed); Debug build exit 65 (failed); Release build exit 65 (failed); full test exit 65 (failed). Exit-code files in the evidence directory match. Full-test command has no `-only-testing` or `-skip-testing`. Failed runs are not represented as passes. |
| 3  | Every baseline diagnostic preserved and attributed (01) | ✓ VERIFIED | Re-checked: `DPArcProgress.swift:33:26` conformance error present in debug-build (line 418), release-build (lines 518, 553) stdout logs; `AddDrinkView.swift:5:30` warning present in debug-build, release-build (2), full-test stdout logs. |
| 4  | Raw evidence referenced by relative path and SHA-256, complete (01) | ✓ VERIFIED | Re-hashed this pass: 8 of 8 stdout/stderr streams under `artifact_root` match the recorded SHA-256 (0 missing, 0 mismatched). The three `.xcresult` bundles exist. `git ls-files` contains 0 `.log` or `.xcresult` paths. |
| 5  | Every scoped tracked path has a candidate or no-candidate disposition (03, 04, 05) | ✓ VERIFIED | Carried forward from the 2026-11-12 15:58 pass. Snapshot `5572753` has 254 scoped tracked paths (re-counted this pass). Inventory files unchanged since (git diff 3d2d914..HEAD is UAT only). |
| 6  | UI and data API leads carry exact `path:line`, availability evidence and disposition (03, 04) | ✓ VERIFIED | Carried forward: 54 `path:line` references resolved against the immutable snapshot tree in the prior pass (0 missing, 0 beyond EOF). Covered inputs unchanged. |
| 7  | Living build/test instructions reproduce the baseline on another Mac (02, 07) | ✓ VERIFIED | Re-checked: `README.md` lines 118-138 and `AGENTS.md` lines 432-446 and 546-562 use `xcrun simctl list devices available`, `export LOCAL_IOS_27_UDID=...`, `xcrun simctl bootstatus "$LOCAL_IOS_27_UDID" -b`, and `-destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID"`. No hard-coded simulator identifier in active docs (prior grep). |
| 8  | Active docs describe the selected toolchain and target consistently (02) | ✓ VERIFIED (override) | Re-checked: README.md line 119 states "Requires **Xcode 27** (Swift 6.4 compiler in Swift 6 language mode)". `docs/architecture.md` states the iOS 27.0 minimum and links the Xcode 27 / Swift 6.4 evidence environment. AGENTS.md states the iOS 27 minimum and simulator steps but no Xcode 27 / Swift 6.4 pin. Owner accepted README.md plus docs/architecture.md as the sole pin (08-UAT.md test 2). Recorded as `PASSED (override)`. No doc names an older compiler or simulator as current. |
| 9  | Present-tense project and focus descriptions agree with the Phase 08 target change; dated history stays dated (02) | ✓ VERIFIED | Carried forward (PROJECT.md, current-focus.md unchanged). `.claude/context/current-focus.md` labels the Phase 08 section "Historical" (line 55). Info I1 below. |
| 10 | History List/ScrollView and context-menu workarounds retained until evidence (03) | ✓ VERIFIED | Carried forward: `08-INVENTORY-UI.md` UI-C-04 and UI-C-05 are Retain with a reconsideration gate. |
| 11 | Swift 6.4 language, standard-library, concurrency and testing opportunities checked against real call sites (04) | ✓ VERIFIED | Carried forward: `08-INVENTORY-DATA.md` ties the Swift 6.4 review to call sites, with retain decisions where no benefit is shown. |
| 12 | Frozen schemas, identity, HealthKit, notification and transfer behavior untouched; substantial proposals decision-gated (04) | ✓ VERIFIED | Re-checked: `git diff --name-only 5287541^ 5572753 -- '*.swift'` returns 0 files. `git diff fb6eba9 HEAD -- drinkpulse/Domain/Persistence/Schemas/` is empty. C008-C012 are gated. |
| 13 | Master inventory accounts for every file, candidate, no-candidate row and baseline diagnostic (05) | ✓ VERIFIED | Carried forward: `08-INVENTORY.md` contains the evidence boundary, area and no-candidate index, candidate crosswalk, baseline diagnostic crosswalk, Swift 6.4 coverage, flagged assumptions, decision-gate rule and approved-only handoff. Failed runs listed as unavailable, not zero. |
| 14 | Each substantial candidate has its own source-backed brief and register row (05) | ✓ VERIFIED | Carried forward: `08-DECISION-C001.md` to `C012.md` exist; `08-DECISION-REGISTER.md` links all twelve. |
| 15 | No substantial replacement authorized by a recommendation alone; only approved scope eligible (05) | ✓ VERIFIED | Carried forward: register rows C001-C012 each carry `approve`, date 2026-09-16, exact scope and reason. Handoff mirrors the twelve approved scopes. |
| 16 | Owner can inspect each brief before choosing approve, retain or defer (06) | ✓ VERIFIED | Carried forward: separate brief files exist. `08-UAT.md` (complete, 3/3 pass, 2026-11-12) confirms owner-decision provenance. |
| 17 | Every substantial candidate has a recorded owner outcome; only approved scope eligible for Phase 09/10 (06) | ✓ VERIFIED | Carried forward: twelve explicit `approve` outcomes in the register; handoff includes approved substantial scope only. |
| 18 | Later-discovered substantial candidates trigger the same brief and discussion gate (06) | ✓ VERIFIED | Carried forward: rule text in `08-DECISION-REGISTER.md` and `08-INVENTORY.md`; owner rule in `.planning/PROJECT.md`. |
| 19 | A developer on another Mac can identify a local iOS 27 simulator and use it for documented commands (07) | ✓ VERIFIED | Same evidence as Truth 7. |
| 20 | README.md and CLAUDE.md identify the baseline as immutable evidence, not a general destination (07) | ✓ VERIFIED (relocated) | README.md lines 121-123 state the baseline identity is evidence, not a general destination. `CLAUDE.md` is now a one-line pointer to AGENTS.md (re-checked), and AGENTS.md carries the same statement at lines 442-446. This is the owner's consolidation (`eb1b635`); CLAUDE.md states "All project instructions live in AGENTS.md". Accepted as the intended relocation. |
| 21 | Every current general build, full-test, scoped-test and coverage command in the living entry points uses the local variable (07) | ✓ VERIFIED | Re-checked: AGENTS.md lines 439-460 and 546-562 and README.md lines 133-138 use `id=$LOCAL_IOS_27_UDID`. CLAUDE.md contains no commands. |
| 22 | `docs/architecture.md` migration topology matches `MigrationPlan.swift` (08) | ✓ VERIFIED | Re-checked: `MigrationPlan.swift` lines 6-14 list `[SchemaV1, SchemaV2, SchemaV3, SchemaV4]` and `[v1ToV2, v2ToV3, v3ToV4]`. `MigrationPlan.swift` last changed 2026-08-17 (commit 6d12cb1). The architecture topology section matches. |
| 23 | Guide marks V1-V3 frozen and V4 live; the next divergence freezes V4, adds SchemaV5 and a `v4ToV5` stage (08) | ✓ VERIFIED | Carried forward: `docs/architecture.md` "Snapshot-on-divergence rule" states the rule. `Schemas/SchemaV1-4.swift` have no diff since `fb6eba9` (re-checked). |

**Score:** 23/23 truths verified (22 VERIFIED, 1 PASSED via owner override). 0 behavior-unverified.

### Roadmap Success Criteria (contract)

| # | Success criterion | Status | Evidence |
| - | ----------------- | ------ | -------- |
| SC1 | iOS 27.0 minimum for app and both test targets in every configuration; SDK, runtime and dependency versions recorded | ✓ VERIFIED | Truth 1 (re-checked); `08-BASELINE.md` records SDK 27.0 and runtime iOS 27.0 (24A434); dependency resolution exit 0. |
| SC2 | Debug and Release diagnostics captured with exact location and availability | ✓ VERIFIED | Truth 3. The baseline records compiler errors and warnings with exact file and line; no deprecation is claimed. |
| SC3 | Every production and test area reviewed; candidates recorded as change, retain or externally blocked, with no-change entries | ✓ VERIFIED | Truths 5, 6, 10. |
| SC4 | Build instructions and living platform docs reflect toolchain and target; baseline result and blockers recorded | ✓ VERIFIED (override) | Truths 1-8 and 19-21. Living docs reflect iOS 27.0 and portable simulator steps. The Xcode 27 / Swift 6.4 pin lives in README.md and docs/architecture.md; AGENTS.md has none. Owner accepted this (08-UAT.md test 2). Recorded as `PASSED (override)`. |
| SC5 | Substantial candidates have reviewable briefs; owner discusses scope before execution planning | ✓ VERIFIED | Truths 14-18. Owner review recorded in 08-UAT.md (2026-09-18 provenance; 2026-11-12 re-confirmation). |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `drinkpulse.xcodeproj/project.pbxproj` | iOS 27 / Swift 6 effective settings | ✓ VERIFIED | Effective values re-checked with `-showBuildSettings` for all six target/configuration combinations. |
| `08-BASELINE.md` + `08-BASELINE.json` | Reproducible, truthful, immutable baseline | ✓ VERIFIED | 8/8 stream hashes match (re-hashed this pass); three xcresult bundles present; exit codes match the narrative. |
| `README.md` | Portable local destination, toolchain pin, baseline link | ✓ VERIFIED | Lines 118-138; line 119 carries the Xcode 27 / Swift 6.4 pin. |
| `AGENTS.md` | Portable destination, baseline link, build commands | ✓ VERIFIED | Lines 432-446 and 546-562. No toolchain pin by design (override on Truth 8). |
| `CLAUDE.md` | Pointer to the instruction source | ✓ VERIFIED | Single pointer to AGENTS.md (Truth 20). |
| `docs/architecture.md` | Source-aligned migration topology and toolchain pin | ✓ VERIFIED | Lines 5-8 state the iOS 27.0 minimum and link the Xcode 27 / Swift 6.4 evidence environment. Topology matches `MigrationPlan.swift`. |
| `drinkpulse/Domain/Persistence/Schemas/SchemaV1-4.swift` | Frozen snapshots (prohibition) | ✓ VERIFIED | Empty diff since `fb6eba9`. |
| `08-INVENTORY-UI.md`, `08-INVENTORY-DATA.md`, `08-INVENTORY.md` | Complete dated inventory | ✓ VERIFIED | Carried forward (Truths 5, 6, 10-13). Judged against the immutable Phase 08 snapshot. |
| `08-DECISION-REGISTER.md` + `C001`-`C012` | Separate owner outcomes and briefs | ✓ VERIFIED | Truths 14-17. Polish prose: owner-accepted warning W1. |
| `08-DOC-AUDIT.md` | Active-doc audit | ✓ VERIFIED | Present. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| Baseline manifest | Project, scheme, configuration, simulator | Exact `xcodebuild` commands | ✓ WIRED | Project, scheme, Debug configuration and simulator identifier agree across `commands` and `simulator`. |
| Baseline manifest | Raw evidence | Relative paths and SHA-256 | ✓ WIRED | 8/8 hashes match (re-hashed this pass). |
| README.md, AGENTS.md | `08-BASELINE.md` | Link | ✓ WIRED | Both links present. |
| `CLAUDE.md` | `AGENTS.md` | Pointer | ✓ WIRED | Relocated link chain (Truth 20). |
| `docs/architecture.md` | `08-BASELINE.md` | Link | ✓ WIRED | Present. |
| `docs/architecture.md` | `MigrationPlan.swift` | Schema/stage topology | ✓ WIRED | Exact match. |
| Inventory candidates | Source `path:line` | Snapshot tree `5572753` | ✓ WIRED | 54/54 resolved in the prior pass; snapshot is immutable. |
| Candidates | Briefs, register, handoff | C001-C012 IDs | ✓ WIRED | 12 briefs, 12 register rows, 12 handoff rows. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
| -------- | ---- | ------ | ------------------ | ------ |
| Settings matrix | Effective target settings | `xcodebuild -showBuildSettings` on live project (this pass) | Yes | ✓ FLOWING |
| Baseline JSON | Runs, hashes, diagnostics | External logs and `.xcresult` bundles | Yes, hash-validated (this pass) | ✓ FLOWING |
| Inventory | Path coverage | Snapshot `git ls-tree 5572753` | 254 scoped paths (this pass) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Effective target settings at HEAD | `xcodebuild -target {drinkpulse,drinkpulseTests,drinkpulseUITests} -configuration {Debug,Release} -showBuildSettings` | 27.0 / 6.0 for all six combinations | ✓ PASS |
| Baseline stream integrity | Python-free SHA-256 recompute over the 8 streams listed in `08-BASELINE.json` | 8 match, 0 missing, 0 mismatched | ✓ PASS |
| Baseline diagnostic attribution | `grep` for `DPArcProgress.swift:33` and `AddDrinkView.swift:5:30` in raw stdout logs | Present in the expected logs | ✓ PASS |
| Frozen schema snapshots | `git diff fb6eba9 HEAD -- drinkpulse/Domain/Persistence/Schemas/` | Empty | ✓ PASS |
| Swift changes in Phase 08 window | `git diff --name-only 5287541^ 5572753 -- '*.swift'` | 0 files | ✓ PASS |
| Tracked evidence leakage | `git ls-files` filtered to `.log` and `.xcresult` | 0 paths | ✓ PASS |
| Full app test suite | Not re-run at HEAD (see re_verification notes) | Not run | SKIP (out of scope: immutable baseline; baseline result already recorded as failed at compile) |

### Probe Execution

No Phase 08 probe declared; no conventional `scripts/**/tests/probe-*.sh` for this phase. SKIPPED.

### Requirements Coverage

Plan `requirements:` fields (re-read this pass) and `REQUIREMENTS.md` traceability (lines 52-55, all four mapped to Phase 08 and marked Complete):

| Requirement | Source Plans | Description | Status | Evidence |
| ----------- | ------------ | ----------- | ------ | -------- |
| PLAT-01 | 08-01 | All app and test targets require iOS 27.0 in every relevant build configuration | ✓ SATISFIED | Truth 1 (re-checked); `REQUIREMENTS.md` line 12 `[x]`. |
| PLAT-02 | 08-01, 08-02, 08-05, 08-07 | Documented Xcode/iOS 27 toolchain; build scripts, resolved dependencies and living docs match the selected baseline | ✓ SATISFIED | Truths 2, 7, 8 (override), 19-21; `REQUIREMENTS.md` line 13 `[x]`. Info I6 notes one post-snapshot build phase not in the baseline. |
| MOD-01 | 08-03, 08-04, 08-05, 08-08 | Complete source-backed candidate and no-candidate inventory | ✓ SATISFIED | Truths 5, 6, 10, 11, 13, 22, 23; `REQUIREMENTS.md` line 17 `[x]`. |
| MOD-05 | 08-03, 08-04, 08-05, 08-06 | Owner reviews concrete substantial-replacement analysis before execution scope | ✓ SATISFIED | Truths 14-18; `REQUIREMENTS.md` line 21 `[x]`. |

**Plan-to-requirement cross-reference:** The plans declare exactly PLAT-01, PLAT-02, MOD-01 and MOD-05. Each phase requirement ID appears in at least one plan. No requirement ID is declared by a plan and absent from REQUIREMENTS.md.

**Orphan check:** REQUIREMENTS.md maps only PLAT-01, PLAT-02, MOD-01 and MOD-05 to Phase 08. All four are accounted for. MOD-02 and MOD-04 belong to Phases 09 and 11 and are out of scope here. No orphaned requirement IDs.

### Decision Coverage

Covered by Truths 14-18, which cover the decision-bearing artifacts (register, briefs, handoff, owner UAT).

## Prohibition Checks

The plan `must_haves.prohibitions` carry `status: unverified` and no `verification:` field, so each is judgment-tier (re-read this pass). The LLM-judge verdicts below were non-authoritative. The owner has now reviewed each one and confirmed it (`08-UAT.md` test 3, pass, 2026-11-12). Under the interactive human-resolution rule, the owner's confirmation is the explicit per-item resolution, so the `unverified-prohibition` flag is cleared for these eight items. The plan files still carry `status: unverified`; this verifier did not edit plan files.

| # | Plan | Prohibition | Verdict | Evidence |
| - | ---- | ----------- | ------- | -------- |
| P1 | 08-01 | Raising the deployment minimum must not reset a SwiftData store or alter a shipped VersionedSchema snapshot | PASS (owner-confirmed) | Schemas unchanged since `fb6eba9` (re-checked); d1760a7 is an effective-setting no-op (re-checked). |
| P2 | 08-01 | Committed baseline must not contain personal health values, signing secrets or bulky raw logs | PASS (owner-confirmed) | 0 tracked `.log` or `.xcresult` paths (re-checked). |
| P3 | 08-02 | Current docs must not imply an older compiler or simulator is the selected evidence environment | PASS (owner-confirmed) | README and architecture name Xcode 27 / iOS 27 as selected; no older toolchain named as current. |
| P4 | 08-03 | An API's age or an unverified skill lookup must not be presented as proof a change is beneficial | PASS (owner-confirmed) | UI-C-04 and UI-C-05 are Retain with no deprecation claim. |
| P5 | 08-04 | Compiler or standard-library novelty must not justify a speculative rewrite of domain, migration, notification or HealthKit semantics | PASS (owner-confirmed) | 0 Swift changes in the Phase 08 window (re-checked); gated rows C008-C011. |
| P6 | 08-05 | Final inventory must not hide a no-candidate area or imply a failed baseline passed | PASS (owner-confirmed) | No-candidate rows present; failed runs listed as unavailable with exit 65. |
| P7 | 08-05 | A substantial candidate must not enter a downstream plan merely because a brief exists | PASS (owner-confirmed) | Handoff and register include only `approve` rows. |
| P8 | 08-06 | A missing response must not be recorded as owner approval | PASS (owner-confirmed) | Twelve explicit `approve` outcomes with date, scope and reason; `08-UAT.md` provenance pass. |

## Warnings

| # | Finding | Category | Disposition |
| - | ------- | -------- | ----------- |
| W1 | Polish-language prose remains in English-only documentation (AGENTS.md "Language: English only"): `08-DECISION-REGISTER.md` "Exact scope" and "Owner reason" columns, `08-INVENTORY.md` handoff "Approved scope" column, owner-response and scope blocks in `08-DECISION-C001..C012.md`, and `08-06-SUMMARY.md` narrative. | Documentation policy | ACCEPTED (owner). Explicit acceptance of the Polish text, `08-UAT.md` test 1 (pass). Not a must-have, so no override entry. The verbatim owner transcript stays as quoted source. |
| W2 | AGENTS.md lacks an Xcode 27 / Swift 6.4 toolchain pin (formerly labelled "Truth 4"; the correct row is Truth 8). | Documentation completeness | ACCEPTED (owner) as `PASSED (override)` on Truth 8 and SC4. The pin is README.md line 119 and docs/architecture.md. |

## Information (non-blocking)

| # | Finding | Disposition |
| - | ------- | ----------- |
| I1 | `.claude/context/current-focus.md` "Historical backlog" item 1 says "use the linked baseline as the only active build/test entry point". It sits under a "Historical" heading and predates the 08-07 portable-destination fix. It conflicts with README and AGENTS, which treat the baseline as evidence. | Optional rewording to "portable local destination flow; baseline linked as evidence". No status effect. |
| I2 | Host runs Xcode 27.2 (27B52). Baseline pins Xcode 27.0 (27A266a). Baseline is immutable and was not re-captured. | None. Expected. |
| I3 | 26 tracked files under scoped directories were added after the Phase 08 snapshot (Phase 09, Phase 10, quick tasks). The inventory is a dated snapshot. | None. A future inventory refresh must cover them. |
| I4 | Phase 10 changed `StoreBootstrap.swift` (not a Phase 08 covered file). Its recovery prose in `docs/architecture.md` is outside Phase 08 scope. | Out of scope. |
| I5 | `AGENTS.md` is a covered input and is the content source for the living simulator instructions. | None. |
| I6 | Commit `4df1f96` added a Debug-only Run Script phase "Embed Git Commit (Debug)" and `ENABLE_USER_SCRIPT_SANDBOXING = NO` to `project.pbxproj`. The script is not in the captured baseline. The Phase 08 baseline commands are unchanged. | Owner awareness. A future re-capture should include it. Not a Phase 08 failure. |
| I7 | Cross-reference numbering in the prior report was wrong (toolchain item labelled "Truth 4"). This report uses the table numbering. | Corrected in this report. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| Phase artifacts and covered living docs | — | Debt-marker scan: no unreferenced markers | ℹ️ Info | No debt-marker blocker. |
| `08-DECISION-REGISTER.md`, `08-INVENTORY.md`, `08-DECISION-C001..C012.md`, `08-06-SUMMARY.md` | multiple | Polish prose in English-only documentation | ℹ️ Info (owner-accepted, W1) | No longer blocking. |

## Human Verification Required

None outstanding. The three items from the prior report were resolved by the owner in `08-UAT.md` (status complete, 3 passed, 0 issues, updated 2026-11-12T20:32:33Z):

1. **Polish prose policy (W1):** accepted as written (`08-UAT.md` test 1).
2. **Toolchain pin in AGENTS.md (W2):** accepted; README.md and docs/architecture.md are the sole pin (`08-UAT.md` test 2). Recorded as override on Truth 8 and SC4.
3. **Judgment-tier prohibitions P1-P8:** confirmed by the owner (`08-UAT.md` test 3).

## Gaps Summary

No BLOCKER. No FAILED truth, missing or stub artifact, unwired key link, or unreferenced debt marker. All four requirement IDs (PLAT-01, PLAT-02, MOD-01, MOD-05) are accounted for. The two former WARNINGs are closed by owner decision and recorded as an override and an accepted warning. The eight prohibitions are owner-confirmed.

The baseline capture itself records failing Debug build, Release build and full-test runs (exit 65). That is the honest result of the captured baseline, and the phase truths require recording pass or fail. It is not a verification failure.

## Advisory (New Scope, Unevidenced)

None. No new-scope blocker was raised in this re-verification pass. Regression spot-checks passed at HEAD 2d1c365.

---

_Verified: 2026-11-12T20:36:28Z_
_Verifier: Claude (gsd-verifier)_
