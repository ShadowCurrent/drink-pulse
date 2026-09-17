---
phase: 08-ios-27-baseline-api-inventory
verified: 2026-09-17T12:18:51Z
status: gaps_found
score: 12/14 must-haves verified
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
  - .planning/phases/08-ios-27-baseline-api-inventory/08-REVIEW.md
  - CLAUDE.md
  - README.md
  - docs/architecture.md
  - drinkpulse.xcodeproj/project.pbxproj
covered_digest: "v1:sha256:49f341818fa80c911faeedb71922e818d7c9a9ef94a9598dda64126b6294ffe2"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Project build instructions and living platform documentation reflect the selected iOS 27 toolchain and target, with reproducible baseline instructions."
    status: failed
    reason: "README.md and CLAUDE.md publish the evidence-capture Mac's fixed simulator UDID as general build/test commands, but provide neither a local reselection step nor a <LOCAL_IOS_27_UDID> placeholder/link to the baseline. Those commands fail on a different developer Mac."
    artifacts:
      - path: "README.md"
        issue: "Lines 118-130 use 1D35E1B8-4141-4EFF-A493-52CB37B600A5 directly; no baseline link or local-destination guidance exists."
      - path: "CLAUDE.md"
        issue: "Lines 426-429 and 522-535 use the same machine-local ID directly; no reselection guidance exists."
    missing:
      - "Keep the fixed ID only in 08-BASELINE.md; add a local iOS 27 simulator selection command and placeholder/equivalent destination to README.md and CLAUDE.md."
      - "Link the living instructions to 08-BASELINE.md for the immutable captured command and result."
  - truth: "The completed source-backed inventory and living technical guidance do not leave a contradicted persistence baseline that could select unsafe code changes."
    status: failed
    reason: "The Phase 08-modified living architecture guide still says the migration plan ends at SchemaV3 and calls V3 live, but the actual MigrationPlan contains SchemaV1-V4 and v3ToV4. Following the guide would freeze the wrong snapshot for the next model change."
    artifacts:
      - path: "docs/architecture.md"
        issue: "Lines 125-147 state schemas [V1,V2,V3], stages [v1ToV2,v2ToV3], V3 live, and 'next divergence freezes V3'."
      - path: "drinkpulse/Domain/Persistence/MigrationPlan.swift"
        issue: "Lines 9-13 define [SchemaV1, SchemaV2, SchemaV3, SchemaV4] and v3ToV4; SchemaV4 is the current live bridge."
    missing:
      - "Update the persistence-bootstrap guide to V1-V4, v1ToV2/v2ToV3/v3ToV4, frozen V1-V3, live V4, and the V4-to-V5 next-divergence rule."
human_verification:
  - test: "Authenticate the owner-decision source for C001-C012."
    expected: "The original owner checkpoint response, rather than only its copied transcript in phase artifacts, explicitly approves each C001-C012 bounded scope and reason."
    why_human: "The register, all twelve briefs, and the approved-only handoff are internally consistent, but repository files cannot prove that the quoted response came from the owner."
---

# Phase 08: iOS 27 Baseline & API Inventory Verification Report

**Phase Goal:** Establish a reproducible iOS 27 baseline and a complete, source-backed inventory before selecting code changes.
**Verified:** 2026-09-17T12:18:51Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | All app, unit-test, and UI-test Debug/Release effective settings are iOS 27.0 and Swift 6.0. | ✓ VERIFIED | Fresh `xcodebuild -showBuildSettings` returned `IPHONEOS_DEPLOYMENT_TARGET = 27.0` and `SWIFT_VERSION = 6.0` for all six target/configuration pairs; the project settings and manifest agree. |
| 2 | The selected Xcode 27/Swift 6.4/iOS 27 simulator baseline records dependency resolution, Debug, Release, and an unfiltered full test invocation truthfully. | ✓ VERIFIED | Current host reports Xcode 27.0 (27A266a), Swift 6.4, SDK 27.0. `08-BASELINE.json` points to existing external logs/bundles; all eight stream hashes match, Debug/Release/full-test exit codes are 65, and the full command has neither test filter. |
| 3 | Every baseline diagnostic/failure is preserved, source-attributed, and not represented as a pass. | ✓ VERIFIED | Raw logs show the `DPArcProgress.swift:33` Shape/main-actor error and `AddDrinkView.swift:5` @Entry warning. `08-BASELINE.md` and the master crosswalk classify the three failed runs and report test counts unavailable, not zero/passing. |
| 4 | Every production, test, resource, and Xcode-tooling path is reviewed with a candidate/no-candidate disposition. | ✓ VERIFIED | Independent `git ls-files` comparison found all 254 scoped tracked paths represented in `08-INVENTORY-UI.md` or `08-INVENTORY-DATA.md`; explicit no-candidate records are present. |
| 5 | Distinct API/pattern leads have exact source locations, official-source/availability evidence, rationale, and change/retain/external disposition. | ✓ VERIFIED | 49 fully-qualified literal `path:line` references resolve to existing current source lines; detailed UI/data registers and master crosswalk contain official URLs, availability wording, evidence, and disposition. |
| 6 | Project build instructions and living platform documentation reproduce the selected baseline on another developer machine. | ✗ FAILED | README.md and CLAUDE.md hard-code the capture machine's simulator UDID without a local reselection path or baseline link. |
| 7 | History List/ScrollView and context-menu workarounds remain retained until focused iOS 27 evidence justifies a change. | ✓ VERIFIED | UI-C-04/UI-C-05 retain the protected behavior, source locations, prior reproduction evidence, and concrete conditions for reconsideration. |
| 8 | Swift 6.4 language, standard-library, concurrency, and testing opportunities are checked against real call sites rather than novelty. | ✓ VERIFIED | `08-INVENTORY-DATA.md` records concrete cleanup, testing, notification, and HealthKit call sites, official Swift/Apple sources, and retain decisions where no benefit is demonstrated. |
| 9 | Frozen schemas, data identity, HealthKit, notification, and transfer behavior are untouched and substantial proposals are decision-gated. | ✓ VERIFIED | No SchemaV1-V4 or MigrationPlan file changed in the Phase 08 commit range; the data inventory identifies V1-V4 as immutable and C008-C012 record bounded, risk-aware decisions. |
| 10 | The master inventory crosswalks all diagnostics, source candidates, no-candidate rows, and later remediation. | ✓ VERIFIED | `08-INVENTORY.md` crosswalks Debug/Release/full-test failure evidence to C002 and Phase 09/11, and keeps test totals unavailable. |
| 11 | Each substantial candidate has a reviewable, source-backed decision brief before execution planning. | ✓ VERIFIED | C001-C012 each contain current/proposed behavior, official source, availability, benefit/cost, alternatives, compatibility, risks, recommendation, and scope; the register links all twelve one-to-one. |
| 12 | No substantial replacement is authorized merely by a recommendation or brief. | ✓ VERIFIED | Phase 09/10 have no plans, and the handoff table includes only registered `approve` rows; routine recommendations are separated. |
| 13 | Each substantial candidate has an authentic owner outcome with exact scope/reason and only approved scope is eligible downstream. | ? UNCERTAIN | The register, 12 briefs, and master handoff pass the plan's cross-artifact validator, but the original owner checkpoint response is unavailable for independent authentication. |
| 14 | Later substantial discoveries must repeat the brief-and-discussion gate while unrelated approved work can continue. | ✓ VERIFIED | `08-DECISION-REGISTER.md` independent-outcome rule and `08-INVENTORY.md` decision-gate rule state this explicitly. |

**Score:** 12/14 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `drinkpulse.xcodeproj/project.pbxproj` | Six iOS 27 / Swift 6 settings | ✓ VERIFIED | Exists, substantive settings, and fresh Xcode setting queries consume them. |
| `08-BASELINE.md` + `08-BASELINE.json` | Reproducible, truthful external baseline | ✓ VERIFIED | Both are substantive; JSON commands, hashes, raw streams, and xcresult directories resolve outside the worktree. |
| `README.md` + `CLAUDE.md` | Active portable build/test instructions | ✗ HOLLOW | Instructions are wired as runnable commands but their fixed remote-machine destination makes them non-portable. |
| `08-DOC-AUDIT.md` | Accurate active-doc audit | ⚠️ INCOMPLETE | It documents the needed reselection procedure but does not wire it into the live commands it audits. |
| `08-INVENTORY-UI.md` + `08-INVENTORY-DATA.md` | Complete detailed source inventory | ✓ VERIFIED | 254/254 scoped tracked paths represented; literal source locations checked. |
| `08-INVENTORY.md` | Master reconciliation and approved-only handoff | ✓ VERIFIED | Links detailed inventories, diagnostics, decisions, and Phase 09/10 handoff. |
| `08-DECISION-REGISTER.md` + `08-DECISION-C001`–`C012` | Reviewable substantial-candidate governance | ⚠️ HUMAN AUTHENTICATION NEEDED | Artifact topology and fields validate; original owner-response provenance cannot be established from repository files. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Baseline manifest | Project/scheme/simulator | Exact `xcodebuild` commands | ✓ WIRED | Project, scheme, Debug/Release configuration, and simulator ID agree across the manifest; both testables are enabled in the shared scheme. |
| Baseline manifest | External raw evidence | Relative paths + SHA-256 | ✓ WIRED | Eight stream files and three xcresult directories exist under the declared external root; every recorded hash matches. |
| Active developer docs | `08-BASELINE.md` | Durable baseline link and portable destination selection | ✗ NOT_WIRED | `README.md` and `CLAUDE.md` do not name/link `08-BASELINE.md` and omit the documented local-UDID procedure. |
| Inventory candidates | Source files/lines | Repository-relative occurrence records | ✓ WIRED | Checked literal current occurrences resolve; complete tracked-path census has no missing files. |
| Substantial candidates | Brief/register/handoff | C001-C012 IDs and approved-only table | ✓ WIRED | One-to-one files/register rows and matching Phase 09/10 handoff pass the Plan 06 validator. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `08-BASELINE.json` | `runs`, diagnostics, hashes | External Xcode logs and `.xcresult` bundles | Existing files with matching SHA-256 and raw compiler output | ✓ FLOWING |
| Detailed inventories | Reviewed paths and source locations | Current `git ls-files` and Swift/Xcode source | 254 current tracked paths; sampled literal locations resolve | ✓ FLOWING |
| README/CLAUDE commands | Simulator destination | Hard-coded capture-machine UDID | No: a new developer has no selection/fallback path | ✗ HOLLOW_PROP |
| Master handoff | Approved scope | Decision register and brief files | Cross-artifact fields agree; owner-origin authenticity needs human confirmation | ⚠️ HUMAN SOURCE NEEDED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Six effective target settings | Six `xcodebuild -showBuildSettings` queries | Each reported iOS 27.0 and Swift 6.0 | ✓ PASS |
| External baseline integrity | Read-only JSON/hash/path validator | All four runs, eight streams, hashes, exit codes, and bundles validated | ✓ PASS |
| Plan-declared deterministic checks | 12 embedded Python checks across Plans 01-06 | All exited 0 | ✓ PASS |
| Full app suite now | Not re-run | Existing Phase 08 raw evidence already proves it stopped at app compilation; a new full run is out of scope and would not resolve the documented failure | ? SKIP |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PLAT-01 | 01 | All app and test targets require iOS 27.0 in every relevant configuration. | ✓ SATISFIED | Fresh six-pair Xcode settings query and committed target settings agree. |
| PLAT-02 | 01, 02, 05 | Developers can build/test with the documented iOS 27 toolchain and matching documentation/dependencies. | ✗ BLOCKED | Toolchain, dependency resolution, and baseline evidence are sound, but active general instructions cannot select a local simulator and lack the required baseline link. |
| MOD-01 | 03, 04, 05 | Complete source-backed candidate/no-candidate inventory. | ✓ SATISFIED | 254/254 scoped files represented, current literal locations resolve, and diagnostics are crosswalked. |
| MOD-05 | 03, 04, 05, 06 | Owner can review concrete substantial-replacement analysis before execution scope. | ? NEEDS HUMAN | Brief content and the approved-only wiring are complete; independently authenticating the owner checkpoint remains manual. |

No orphaned Phase 08 requirements were found: all four roadmap-mapped IDs are claimed by one or more of the six plans.

### Decision Coverage

`check.decision-coverage-verify` reported all 13/13 trackable `08-CONTEXT.md` decisions honored. This is a non-blocking coverage signal, not proof that the two documentation defects are resolved.

### Test Quality Audit

No Phase 08 production/test implementation or requirement-linked test was added. The phase's executable evidence is the baseline capture and read-only validators; there are no disabled or circular requirement tests to audit. The captured unfiltered full suite is correctly recorded as blocked by compilation, not as passing test evidence.

### Independent Assessment of `08-REVIEW.md`

| Finding | Review verdict | Independent result | Evidence |
| --- | --- | --- | --- |
| CR-01: obsolete schema migration path | BLOCKER | ✓ CONFIRMED — BLOCKER | `docs/architecture.md:125-147` says V1-V3/V3-live, while `MigrationPlan.swift:9-13` defines V1-V4 plus `v3ToV4`. |
| WR-01: capture-machine simulator UDID in general instructions | WARNING | ✓ CONFIRMED — BLOCKER for PLAT-02 | README and CLAUDE hard-code `1D35E1B8-4141-4EFF-A493-52CB37B600A5`; only `08-DOC-AUDIT.md`, not the live commands, supplies local reselection. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `README.md` | 118-130 | Machine-specific simulator destination presented as general command | 🛑 Blocker | A developer cannot reproduce the documented baseline on another Mac. |
| `CLAUDE.md` | 426-429, 522-535 | Same hard-coded simulator destination; no fallback/link | 🛑 Blocker | Build, full-test, scoped-test, and coverage instructions are non-portable. |
| `docs/architecture.md` | 125-147 | Stale V1-V3 migration topology | 🛑 Blocker | Could cause an unsafe next schema change by freezing V3 rather than V4. |

The Phase 08-modified files contain no unresolved `TBD`, `FIXME`, or `XXX` debt markers. Static checks also found no raw build/test log or xcresult tracked in the phase directory; the baseline references external evidence by path and hash. The frozen schema/migration files are unchanged across the Phase 08 implementation commit range.

### Prohibition Checks

| Prohibition | Status | Evidence |
| --- | --- | --- |
| Raising deployment minimum must not mutate frozen schemas or reset the store. | ✓ VERIFIED (static) | No Phase 08 diff touches `SchemaV1`-`SchemaV4` or `MigrationPlan`; no Phase 08 code invokes store reset. |
| Committed baseline must not contain health values, signing secrets, or raw logs. | ✓ VERIFIED (static) | Raw streams/bundles are outside Git; committed baseline contains command metadata, paths, hashes, and classifications. |
| Current instructions must not imply an older evidence compiler/simulator. | ✗ FAILED | They correctly specify iOS 27/Xcode 27, but wrongly imply the capture-machine simulator is portable; the resulting reproducibility defect is a blocker. |
| Recommendations/briefs must not become approval by silence. | ? HUMAN AUTHENTICATION NEEDED | Repository copies an owner-response transcript consistently, but cannot authenticate its origin. |

### Human Verification Required

### 1. Owner decision provenance

**Test:** Compare the original 2026-09-16 owner checkpoint response with every C001-C012 register/brief outcome.

**Expected:** The original response explicitly supports the candidate IDs, `approve` outcomes, exact bounds, and rationale recorded in the repository.

**Why human:** Repository documents can prove internal consistency but not speaker identity or the authenticity of a copied transcript.

### Gaps Summary

The baseline capture and source inventory are substantive and source-backed, but the phase goal is not achieved because the living developer instructions cannot reproduce the selected iOS 27 baseline on another machine. The Phase 08 documentation work also left a confirmed, dangerous contradiction between the authoritative persistence guide and the actual V1-V4 migration plan. Neither defect is explicitly and specifically scheduled in a later roadmap phase, so neither is deferred.

---

_Verified: 2026-09-17T12:18:51Z_
_Verifier: the agent (gsd-verifier)_
