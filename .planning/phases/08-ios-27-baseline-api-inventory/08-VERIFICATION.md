---
phase: 08-ios-27-baseline-api-inventory
verified: 2026-11-08T13:02:42Z
status: passed
score: 14/14 must-haves verified
covered_files:
  - .claude/context/current-focus.md
  - .planning/PROJECT.md
  - .planning/REQUIREMENTS.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-01-PLAN.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-01-SUMMARY.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-02-PLAN.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-02-SUMMARY.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-03-PLAN.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-03-SUMMARY.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-04-PLAN.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-04-SUMMARY.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-05-PLAN.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-05-SUMMARY.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-06-PLAN.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-06-SUMMARY.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-07-PLAN.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-07-SUMMARY.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-08-PLAN.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-08-SUMMARY.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.json
  - .planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C001.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C002.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C003.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C004.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C005.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C006.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C007.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C008.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C009.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C010.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C011.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C012.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-REGISTER.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-DOC-AUDIT.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-DATA.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-UI.md
  - .planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY.md
  - CLAUDE.md
  - README.md
  - docs/architecture.md
  - drinkpulse.xcodeproj/project.pbxproj
  - drinkpulse/Domain/Persistence/MigrationPlan.swift
covered_digest: "v4:sha256:c7ce3d459948924c9c80d1c224bdae99c5327a3d0f911b72c0ea341bd7ea9ad7"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 14/14
  previous_verified: 2026-09-18T08:00:28Z
  reason: "Stale: covered files changed after the prior run (CLAUDE.md consolidated into AGENTS.md; current-focus.md updated in Phase 09 bookkeeping; PROJECT.md and REQUIREMENTS.md updated by the phase-completion commit 5572753)."
  gaps_closed: []
  gaps_remaining: []
  regressions: []
  relocated_evidence:
    - "Simulator-destination contract and baseline link: formerly asserted in CLAUDE.md; now in AGENTS.md section 'Local iOS 27 simulator destination' (CLAUDE.md is a one-line pointer to AGENTS.md). README.md carries the same contract."
---

# Phase 08: iOS 27 Baseline & API Inventory Verification Report

**Phase Goal:** Establish a reproducible iOS 27 baseline and a complete, source-backed inventory before selecting code changes.
**Requirements:** PLAT-01, PLAT-02, MOD-01, MOD-05
**Verified:** 2026-11-08T13:02:42Z
**Status:** passed
**Re-verification:** Yes — prior report (2026-09-18) was stale after covered-file changes; all must-haves re-checked against the current tree.

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
| -- | ----- | ------ | -------- |
| 1  | Effective Debug and Release settings of `drinkpulse`, `drinkpulseTests`, `drinkpulseUITests` are iOS 27.0 and Swift 6.0 (PLAT-01) | ✓ VERIFIED | Fresh `xcodebuild -project drinkpulse.xcodeproj -alltargets -configuration {Debug,Release} -showBuildSettings` (Xcode 27.2, 27B52 on this host): all three targets print `IPHONEOS_DEPLOYMENT_TARGET = 27.0` and `SWIFT_VERSION = 6.0` in both configurations. |
| 2  | The baseline records dependency resolution, Debug build, Release build and an unfiltered full test truthfully (PLAT-02) | ✓ VERIFIED | `08-BASELINE.json` runs: dependency resolution exit 0 (passed); Debug build exit 65 (failed); Release build exit 65 (failed); full test exit 65 (failed). Full-test command has no `-only-testing`/`-skip-testing` filter. Exit-code files in the external capture agree. Recorded toolchain: Xcode 27.0 (27A266a), Apple Swift 6.4, iOS 27.0 SDK, simulator runtime iOS 27.0. Failed runs are not represented as passes. |
| 3  | Every baseline diagnostic is preserved, attributed to source, and not represented as a pass | ✓ VERIFIED | Raw `debug-build.stdout.log` line 418 and `release-build.stdout.log` lines 518/553 contain the `DPArcProgress.swift:33:26` error; `AddDrinkView.swift:5:30` warning appears at lines 436/536/571. Both are in `08-BASELINE.json` diagnostics with evidence pointers. |
| 4  | Raw evidence is referenced by relative path and SHA-256 from the committed manifest and is complete | ✓ VERIFIED | Independent check: 8 of 8 stdout/stderr streams under `/Users/fempter/Library/Logs/DrinkPulse/phase-08-ios27/20260916T200000Z` exist and match their recorded SHA-256; all three `.xcresult` bundles exist. No `.xcresult` or `.log` file is tracked in Git. |
| 5  | Every scoped tracked production, test, resource and Xcode-tooling path has a candidate or no-candidate disposition (MOD-01) | ✓ VERIFIED | `git ls-files` returns 254 paths under `drinkpulse/`, `drinkpulseTests/`, `drinkpulseUITests/`, `drinkpulse.xcodeproj/`; every one is literally named in `08-INVENTORY-UI.md`, `08-INVENTORY-DATA.md` or `08-INVENTORY.md`. Explicit NC-UI-xx / no-candidate rows exist for each UI area. |
| 6  | Distinct API/pattern leads carry exact `path:line` locations, official-source/availability evidence, rationale and a change/retain/external disposition (MOD-01) | ✓ VERIFIED | 51 distinct `path:line` references plus brace-grouped references (for example `Features/History/Components/{CustomNameSuggestionSection.swift:25,...}`) were resolved against the tree. All point to existing files within EOF; spot-checked lines (`DPArcProgress.swift:33`, `AddDrinkView.swift:5`, `CustomNameSuggestionSection.swift:25`, `GuidelineComparisonCard.swift:11`, `AlcoholAreaChart.swift:10`) match the claimed constructs. Line content drift from Phase 09 edits is expected and does not change the Phase 08 snapshot. |
| 7  | Living build and test instructions reproduce the selected baseline on another developer machine (PLAT-02) | ✓ VERIFIED | `AGENTS.md` lines 432-446 ("Local iOS 27 simulator destination") and `README.md` lines 118-137 define `xcrun simctl list devices available`, `export LOCAL_IOS_27_UDID=...`, `xcrun simctl bootstatus "$LOCAL_IOS_27_UDID" -b`, and link `08-BASELINE.md`. Every `-destination` argument in README.md and AGENTS.md (6 occurrences: build, full test, scoped test, coverage) uses `$LOCAL_IOS_27_UDID`; no hard-coded UDID or device name remains in active instructions. `CLAUDE.md` is a pointer to AGENTS.md (see Re-verification notes). |
| 8  | Active docs describe the selected toolchain and target consistently; historical dates stay historical (PLAT-02) | ✓ VERIFIED | `AGENTS.md` line 22 and `README.md` line 6 state iOS 27.0 minimum; README line 118 requires Xcode 27 (Swift 6.4 compiler, Swift 6 mode). `.claude/context/current-focus.md` labels the iPhone 17 Pro (Phase 07) and iPhone 18 Pro baseline sections as historical; its cited links (`08-BASELINE.md`, `09-RETAIN-EVIDENCE.md`) resolve. |
| 9  | History List/ScrollView and context-menu workarounds stay retained until focused iOS 27 evidence justifies a change | ✓ VERIFIED | `08-INVENTORY-UI.md` rows UI-C-04 (List/ScrollView split, `HistoryListQueryView.swift:39-81`) and UI-C-05 (context menu, `EventContextMenu.swift:5-58`) carry retain dispositions with reconsideration gates. |
| 10 | Swift 6.4 language, standard-library, concurrency and testing opportunities are checked against real call sites (MOD-01) | ✓ VERIFIED | `08-INVENTORY-DATA.md` records Swift 6.4 coverage (9 references) tied to current call sites and retain decisions where no demonstrated benefit exists. |
| 11 | Frozen schemas, data identity, HealthKit, notification and transfer behavior are untouched by Phase 08 and substantial proposals are decision-gated | ✓ VERIFIED | `git diff fb6eba9 HEAD -- drinkpulse/Domain/Persistence/` and `git diff fb6eba9 HEAD -- drinkpulse.xcodeproj/project.pbxproj` are empty. Across the Phase 08 commit window (`5287541^`..`3cb8df5^`) the only Swift-adjacent change is the `project.pbxproj` deployment-target commit (`d65f82d`); no `.swift` file changed. C008-C012 cover schema, backup, notifications, HealthKit and cleanup. |
| 12 | The master inventory crosswalks baseline diagnostics, candidates, no-candidate rows and later-phase remediation (MOD-01) | ✓ VERIFIED | `08-INVENTORY.md` sections: Evidence boundary, Area and no-candidate index, Distinct candidate crosswalk, Baseline diagnostic and test-result crosswalk, Swift 6.4 coverage, Flagged assumptions, Decision-gate rule, approved-only handoff. Failed runs are listed as unavailable, not zero. |
| 13 | Each substantial candidate has its own reviewable, source-backed decision brief before execution planning (MOD-05) | ✓ VERIFIED | `08-DECISION-C001.md` through `C012.md` exist, each with the required sections (current behavior, source-backed decision table, availability, recommendation). `08-DECISION-REGISTER.md` links all twelve. |
| 14 | No substantial replacement is authorized by a recommendation alone; each approved scope is bounded and only approved scope is eligible downstream (MOD-05) | ✓ VERIFIED | Register rows C001-C012 each carry `approve`, decision date 2026-09-16, exact scope and owner reason. Approved-only handoff in `08-INVENTORY.md` ("Substantial scope eligible for Phase 09/10") mirrors those twelve bounded scopes. Pending, retained, deferred and silent items are excluded. Later discoveries must repeat the brief-and-discussion gate (register and inventory rule). |

**Score:** 14/14 truths verified (0 present-but-behavior-unverified)

### Roadmap Success Criteria (contract)

| # | Success criterion | Status | Evidence |
| - | ----------------- | ------ | -------- |
| SC1 | iOS 27.0 minimum for app and both test targets in every relevant configuration; SDK/runtime and dependency versions recorded | ✓ VERIFIED | Truth 1; SDK 27.0 and runtime iOS 27.0 build 24A434 recorded in `08-BASELINE.md`/JSON; dependency resolution recorded (exit 0, no resolved source packages). |
| SC2 | Debug and Release baseline diagnostics captured with exact source location and Apple/compiler availability information | ✓ VERIFIED | Truth 3; compiler diagnostics recorded with locations. The baseline contains compiler errors/warnings, not deprecation diagnostics; no deprecation is claimed. |
| SC3 | Every production and test area reviewed; each candidate recorded as change, retain or externally blocked, with no-change entries | ✓ VERIFIED | Truths 5, 6, 9. |
| SC4 | Build instructions and living platform docs reflect the toolchain and target; baseline result and blockers recorded without hiding warnings | ✓ VERIFIED | Truths 7, 8; baseline failures and warnings preserved in `08-BASELINE.md`. |
| SC5 | Substantial candidates have reviewable briefs; owner discusses scope before execution planning; later discoveries use the same gate | ✓ VERIFIED | Truths 13, 14; owner provenance confirmed in `08-UAT.md` (status complete, 1/1 pass, 2026-09-18). |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `drinkpulse.xcodeproj/project.pbxproj` | Six iOS 27 / Swift 6 settings | ✓ VERIFIED | Fresh build-settings query confirms all six pairs. Unchanged since the Phase 08 baseline commit. |
| `08-BASELINE.md` + `08-BASELINE.json` | Reproducible, truthful baseline | ✓ VERIFIED | Eight streams hash-match; three bundles exist; exit codes match the narrative. |
| `README.md` | Portable local destination + baseline link | ✓ VERIFIED | Lines 118-137. |
| `AGENTS.md` | Portable local destination + baseline link (content of former CLAUDE.md section) | ✓ VERIFIED | Lines 432-446 and build commands at 548-562. |
| `CLAUDE.md` | Pointer to the instruction source | ✓ VERIFIED | Contains a single pointer to AGENTS.md, so it adds no simulator or baseline text of its own. The Phase 08 must-have that named CLAUDE.md is satisfied through AGENTS.md (see Re-verification notes). |
| `docs/architecture.md` | Source-aligned persistence topology | ✓ VERIFIED | Lines 124-150 list `SchemaV1..V4`, the three stages, V1-V3 frozen, V4 live, and the V4-to-V5 rule. These match `MigrationPlan.swift` (`schemas = [V1,V2,V3,V4]`, `stages = [v1ToV2, v2ToV3, v3ToV4]`). |
| `08-INVENTORY-UI.md` + `08-INVENTORY-DATA.md` | Complete detailed inventory | ✓ VERIFIED | Truths 5, 6, 10. |
| `08-INVENTORY.md` | Master reconciliation and approved-only handoff | ✓ VERIFIED | Truth 12, 14. |
| `08-DECISION-REGISTER.md` + C001-C012 | Reviewable, separately recorded owner outcomes | ✓ VERIFIED | Truths 13, 14. |
| `08-DOC-AUDIT.md` | Active-doc audit | ✓ VERIFIED | Present; records dispositions for CLAUDE.md, current-focus.md, and historical iPhone 17 Pro references. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| Baseline manifest | Project / scheme / simulator | Exact `xcodebuild` commands | ✓ WIRED | Project, scheme, configuration and destination UDID agree with the toolchain section. |
| Baseline manifest | External raw evidence | Relative paths + SHA-256 | ✓ WIRED | 8/8 stream hashes match; bundles exist. |
| README.md and AGENTS.md | `08-BASELINE.md` | Immutable link | ✓ WIRED | Both links resolve. |
| `CLAUDE.md` | `AGENTS.md` | Pointer | ✓ WIRED | Project-instruction entry point resolves to the file that carries the content. |
| `current-focus.md` | `08-BASELINE.md`, `09-RETAIN-EVIDENCE.md` | Relative links | ✓ WIRED | Both targets exist. |
| Persistence guide | `MigrationPlan.swift` | Schema/stage topology | ✓ WIRED | Exact match on the schema and stage lists. |
| Inventory candidates | Source files and lines | `path:line` | ✓ WIRED | All checked locations resolve. |
| Substantial candidates | Brief / register / handoff | C001-C012 IDs | ✓ WIRED | Twelve briefs, twelve register rows, twelve handoff rows; scopes match. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
| -------- | ---- | ------ | ------------------ | ------ |
| `08-BASELINE.json` | Runs, diagnostics, hashes | External Xcode logs and `.xcresult` bundles | Yes, hash-validated | ✓ FLOWING |
| Settings matrix | Effective target settings | `xcodebuild -showBuildSettings` on the live project | Yes, reproduced this run | ✓ FLOWING |
| Inventory | Path coverage | `git ls-files` | 254/254 literal coverage | ✓ FLOWING |
| Owner handoff | Approved scope | Register rows | Consistent across register, briefs and handoff | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Six effective target settings | `xcodebuild -project drinkpulse.xcodeproj -alltargets -configuration {Debug,Release} -showBuildSettings` | All three targets: `IPHONEOS_DEPLOYMENT_TARGET = 27.0`, `SWIFT_VERSION = 6.0` in both configurations | ✓ PASS |
| External baseline integrity | Python: parse `08-BASELINE.json`, check each stream path and SHA-256 under `artifact_root`, check bundles | 8 streams match, 0 missing, 0 mismatched; 3 bundles present | ✓ PASS |
| Diagnostic attribution | `grep` for `DPArcProgress.swift:33` and `AddDrinkView.swift:5` in raw stdout logs | Found in Debug and Release logs as recorded | ✓ PASS |
| Inventory path coverage | Python: `git ls-files` scoped paths vs inventory text | 254 scoped, 0 unmentioned | ✓ PASS |
| Inventory location resolution | Python: parse `path:line` (including brace groups) against tree | All resolve to existing files within EOF | ✓ PASS |
| Full app test suite | Not re-run | The recorded baseline already fails before tests start; a fresh suite is a long run outside this documentation-phase re-verification | ? SKIP |

### Probe Execution

No Phase 08 probe was declared, and no conventional `scripts/**/tests/probe-*.sh` exists for this phase. SKIPPED.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| ----------- | ------------ | ----------- | ------ | -------- |
| PLAT-01 | 08-01 | All app and test targets require iOS 27.0 in every relevant configuration | ✓ SATISFIED | Truth 1; `REQUIREMENTS.md` checkbox and traceability now read complete (updated in commit `5572753`). |
| PLAT-02 | 08-01, 08-02, 08-05, 08-07 | Documented Xcode/iOS 27 toolchain; build scripts, dependencies and living docs match the baseline | ✓ SATISFIED | Truths 2, 7, 8. |
| MOD-01 | 08-03, 08-04, 08-05, 08-08 | Complete source-backed candidate/no-candidate inventory | ✓ SATISFIED | Truths 5, 6, 9, 10, 12; V1-V4 persistence guide corrected (08-08). |
| MOD-05 | 08-03, 08-04, 08-05, 08-06 | Owner can review concrete substantial-replacement analysis before execution scope | ✓ SATISFIED | Truths 13, 14; owner provenance confirmed in `08-UAT.md`. |

**Orphan check:** `REQUIREMENTS.md` traceability maps only PLAT-01, PLAT-02, MOD-01 and MOD-05 to Phase 08. All four appear in at least one Phase 08 plan `requirements:` field, and every Phase 08 plan ID maps to one of these four. No orphaned requirements.

### Decision Coverage

Not re-run in this pass. The prior run recorded 13/13 trackable `08-CONTEXT.md` decisions honored; this pass re-checked the decision-bearing artifacts (register, briefs, handoff, baseline) directly through Truths 1-14.

## Re-verification Notes (drift since 2026-09-18)

The prior report was stale. Covered-file drift was checked file by file against `git log --since=2026-09-18T08:00:28Z`:

- **`CLAUDE.md`** changed (`eb1b635 docs: consolidate project agent instructions`). It is now a one-line pointer to `AGENTS.md`. Every must-have that named CLAUDE.md was re-checked against `AGENTS.md` and `README.md`. The simulator-destination section, the `LOCAL_IOS_27_UDID` contract, the `xcrun simctl list devices available` step, and the `08-BASELINE.md` link are all present in AGENTS.md. README.md carries the same contract. The relocation satisfies the intent of the plan 08-07 must-haves.
- **`.claude/context/current-focus.md`** changed in Phase 09 bookkeeping (`a5c53bb`, `032fd95`). The Phase 08 section is labeled historical and its claims match the baseline (Xcode 27.0 27A266a, Swift 6.4, `SWIFT_VERSION = 6.0`, failed Debug/Release/full-test runs at `DPArcProgress.swift:33`). The Phase 09 status claims match `09-RETAIN-EVIDENCE.md` (49 selected UI tests, 0 failures, 869.086 seconds, iPhone 18 Pro `1D35E1B8-...`).
- **`.planning/PROJECT.md` and `.planning/REQUIREMENTS.md`** also changed in the phase-completion commit `5572753`, which came after the prior run. They are not listed in the orchestrator's note. Both changes are bookkeeping: the iOS27-BASE item moved to Validated, and PLAT-01 moved to complete. Both files stay in the covered set.
- **Host toolchain drift.** This host now runs Xcode 27.2 (27B52). The baseline and its commands remain pinned to the immutable capture (Xcode 27.0, 27A266a). The living docs say "Requires Xcode 27" without pinning a build, so they stay accurate. The baseline is not re-captured in this pass.
- **Phase 09 source edits** (`DPArcProgress.swift`, `AddDrinkView.swift`, `DrinkDetailInputView*.swift`, `DashboardView.swift`, `GuidelineLimits.swift`, two UI-test files) are expected and out of Phase 08 scope. The Phase 08 window itself (`5287541^`..`3cb8df5^`) contains no `.swift` change. Inventory line locations that point into Phase 09-edited files still resolve. Where a construct moved, the snapshot is the authoritative Phase 08 record and is not rewritten.
- **Fingerprint.** `covered_files` keeps the prior set, which the orchestrator asked to preserve. `covered_digest` was generated by `gsd-tools query verification.fingerprint` and copied verbatim. `AGENTS.md` is not in the covered set. It is the content source for the living simulator instructions, so a future fingerprint regeneration should consider adding it.

## Warnings (non-blocking)

| # | Finding | Category | Disposition |
| - | ------- | -------- | ----------- |
| W1 | Phase 08 artifacts contain Polish-language prose, contrary to AGENTS.md "Language: English only" for every `.md` file. Examples: the "Exact scope" and "Owner reason" columns of `08-DECISION-REGISTER.md` (12 rows), the `Approved scope` column of the handoff in `08-INVENTORY.md` (lines 136-147), `08-DECISION-C001..C012.md` owner-response/scope blocks, and the narrative of `08-06-SUMMARY.md`. | Documentation policy | WARNING. Does not defeat any must-have; the owner's decisions and bounds are unambiguous. Human decision: translate the paraphrased fields to English while keeping the verbatim owner transcript as quoted source, or accept the Polish as quoted owner text. Status unaffected. |
| W2 | `08-SECURITY.md` lists 23 threat rows: 22 mitigate-rows closed, and T-08-19 recorded as an accepted risk in the accepted-risk log. `threats_open: 0` holds. | Information | No action. |
| W3 | `current-focus.md` backlog item 3 (Domain coverage 89.39%) and item 4 (`#Index`, not present in `drinkpulse/`, consistent with "deferred") were not re-measured in this pass. | Information | Historical backlog statements outside Phase 08 must-haves. Not verified here. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `.planning/phases/08-ios-27-baseline-api-inventory/*.md`, `README.md`, `AGENTS.md`, `CLAUDE.md`, `.claude/context/current-focus.md`, `docs/architecture.md` | — | No unresolved `TBD`, `FIXME` or `XXX` marker | ℹ️ Info | No debt-marker blocker. |
| `08-DECISION-REGISTER.md` and related | multiple | Polish-language prose in English-only documentation | ⚠️ Warning | See W1. |
| `08-BASELINE.md` / `08-BASELINE.json` | — | No tracked raw logs, `.xcresult` bundles or health values | ℹ️ Info | Prohibition holds. |

## Prohibition Checks

| Prohibition | Status | Evidence |
| ----------- | ------ | -------- |
| Raising the deployment minimum must not reset a store or alter a shipped VersionedSchema snapshot | ✓ VERIFIED (static) | No change under `drinkpulse/Domain/Persistence/` since `fb6eba9`. |
| The committed baseline must not contain personal health values, signing secrets or bulky raw logs | ✓ VERIFIED (static) | Zero tracked `.log` or `.xcresult` paths; raw evidence is external and hashed. |
| Current instructions must not imply an older compiler or simulator is selected evidence | ✓ VERIFIED | AGENTS.md and README.md require Xcode 27 / Swift 6.4 / iOS 27 and treat the capture-machine UDID as evidence, not a destination. |
| A missing response or recommendation must not be treated as owner approval | ✓ VERIFIED | All twelve register rows carry an explicit `approve` outcome with date, scope and reason; the owner provenance UAT passed. |

## Human Verification

No open items. The prior human item (owner-decision provenance for C001-C012) was resolved in `08-UAT.md` (status complete, 1/1 pass, 2026-09-18): the original 2026-09-16 owner response explicitly approves each candidate's bounded outcome.

## Gaps Summary

No gaps. All 14 must-haves and all five roadmap success criteria are verified against the current tree. All four requirement IDs are accounted for. The only open items are the non-blocking Polish-language warning (W1) and informational drift notes above.

---

_Verified: 2026-11-08T13:02:42Z_
_Verifier: Claude (gsd-verifier)_
