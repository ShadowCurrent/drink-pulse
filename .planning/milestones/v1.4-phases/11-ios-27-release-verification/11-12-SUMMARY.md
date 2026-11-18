---
phase: 11-ios-27-release-verification
plan: 12
subsystem: testing
tags: [accessibility, xcuiautomation, audit-harness, record-correction, owner-decisions]
requires: []
provides:
  - hardened gated audit harness (navigation guard, appearance pinning, locatable keys)
  - corrected exploratory audit record with unreliable rows marked
  - owner decisions D11-23 to D11-27 recorded in briefs and CONTEXT
affects: [11-13, 11-14, 11-16, 11-19, 11-24]
tech-stack:
  added: []
  patterns: ["shared audit support types in the Shell UI-test folder", "appearance pinned for every audit variant with teardown registered first"]
key-files:
  created:
    - drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift
  modified:
    - drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift
    - .planning/phases/11-ios-27-release-verification/11-EVIDENCE.md
    - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md
    - .planning/phases/11-ios-27-release-verification/11-REVIEW-DISPOSITION.md
    - .planning/phases/11-ios-27-release-verification/11-CONTEXT.md
    - .planning/phases/11-ios-27-release-verification/11-DECISION-C014.md
    - .planning/phases/11-ios-27-release-verification/11-DECISION-C015.md
    - .planning/phases/11-ios-27-release-verification/11-DECISION-C016.md
    - .planning/phases/11-ios-27-release-verification/11-DECISION-OBS-A.md
    - .planning/phases/11-ios-27-release-verification/11-DECISION-OBS-C.md
    - .planning/todos/pending/2026-11-14-fix-accessibility-audit-findings.md
    - docs/DEVLOG.md
key-decisions:
  - "The exploratory record is superseded by plan 11-13's refreshed baseline, not deleted"
  - "311 stays the correct byte-wise distinct key count; 254 from 11-VERIFICATION.md is a sort -u locale artifact"
requirements-completed: []
status: complete
commits: 3
plan_head_before: 78a473205c24c3ef5cbe7a3b631cb89dfba5225f
plan_head_after: ec62c6a89932d575fa1cf8ab33d12a6d8822e505
actuals:
  tokens: 30000
  tasks: 3
  commits: 3
duration: 30 min
completed: 2026-11-16
---

# Phase 11 Plan 12: Audit harness hardening and audit record correction Summary

Gated accessibility audit harness now stops on navigation failure and pins appearance for every variant, unlabeled elements get locatable keys, the exploratory audit record marks nine rows as unreliable, and the owner decisions of 2026-11-16 (D11-23 to D11-27) are recorded.

## Accomplishments

- **Harness (Task 1, commit 72bbd30):** `open(_:in:) -> Bool` with `guard open(screen, in: app) else { return }` (WR-01); appearance read, one teardown registered first, then `.dark` or `.light` for every variant (WR-02); `AccessibilityAuditKey` and `AuditLaunch` moved to `AccessibilityAuditSupport.swift`; unlabeled elements keyed `none#type=<elementType rawValue>@x,y,w,h`; hard-coded count removed from comments and skip message (IN-02); dark-variant limit documented (IN-03). Every issue still fails its test, no allow-list. Xcode MCP: build succeeded, 0 warning entries, 0 diagnostics in both files, ungated run 16 skipped / 0 failed (`audit-gated-2.result.txt` in the stamp directory).
- **Record (Task 2, commit a3610c7):** counts recomputed from the saved files; nine unreliable rows named; Record integrity subsection added; ledger header renamed to "Distinct keys (corrected)"; todo carries WR-01, WR-02, D11-25, D11-26; nine documents corrected; WR-01, WR-02, IN-02 marked fixed; DEVLOG entry appended (14 lines added, none changed).
- **Decisions (Task 3, commit ec62c6a):** C014, C015, C016 briefs filled (decision change, 2026-11-16); OBS-A and OBS-C stay pending with a dated note and the G05 boundary; CONTEXT gains D11-23 to D11-27 and errata under D11-17, D11-21, D11-22 (only added lines).

## Apple API record

Read with Xcode MCP DocumentationSearch and the Xcode 27.2 SDK headers:
- `XCUIAccessibilityAuditType` (struct, XCUIAutomation): the search returned the type page and its `init(rawValue:)`; the member list was read from `XCUIAccessibilityAuditTypes.h` (iOS 17.0 and later, inside the iOS 27.0 deployment target).
- `XCUIAccessibilityAuditIssue` (`element`, `auditType`), `XCUIElementAttributes` (`identifier`, `label`, `elementType`, `frame`) and `XCUIDevice.appearance` ("Use this property to get or set the interface appearance ... capture the initial appearance value"): available in the iOS 27.0 deployment target; the documentation extracts carry no older-availability line.

## Deviations from Plan

**1. [Rule 1 - Bug] The "254 distinct keys / 57 repeats" premise is wrong**
- **Found during:** Task 2 recomputation.
- **Issue:** the plan (from 11-VERIFICATION.md T18) expects `sort -u | wc -l` = 254. That is a locale artifact: under pl_PL.UTF-8 `sort -u` treats different emoji element names as equal. `LC_ALL=C sort -u` gives 311 and a Python set of the lines gives 311; the key file has no repeated line. 385 reports collapse to 311 byte-wise distinct keys; the original D11-22 figure was correct as a distinct count.
- **Fix:** documents state "385 reports, 311 byte-wise distinct keys (exploratory record, corrected)", record the locale artifact and the recomputation commands, and never present 254 as a count. The real record defect (nine rows ran in dark appearance) is recorded as planned. The Task 2 and Task 3 verify commands pass (the quoted phrase "254 distinct keys" occurs once, in the correction note); the D11-22 erratum text differs from the plan's literal text for the same reason.
- **Files modified:** 11-EVIDENCE.md, 11-DEBT-LEDGER.md, todo, living docs, 11-CONTEXT.md erratum, DEVLOG.
- **Commits:** a3610c7, ec62c6a.

**2. [Rule 3 - Blocker] `action` and `parentChild` audit types do not exist on iOS**
- **Found during:** Task 1 build ("Type 'XCUIAccessibilityAuditType' has no member 'action'").
- **Issue:** `XCUIAccessibilityAuditTypes.h` defines them only under `TARGET_OS_OSX || TARGET_OS_MACCATALYST`.
- **Fix:** both fall through to the `raw<rawValue>` default in `typeName(for:)`; noted in the doc comment. No audit type is excluded.
- **Files modified:** AccessibilityAuditSupport.swift. **Commit:** 72bbd30.

**3. [Rule 1 - commit message]** The task 1 commit was amended once before any other work to remove the AI attribution trailer, per AGENTS.md (no AI attribution in commit messages).

**Total deviations:** 3 (1 bug in the plan premise, 1 blocker, 1 commit-hygiene). **Impact:** the corrected record is accurate; the owner should confirm the 254-versus-311 finding because plans 11-13 and 11-24 were written against 254.

## Known Stubs

None.

## Threat Flags

None. No production file, network call, logging or schema changed.

## Issues Encountered

- The review disposition footer still says "Phase 11 makes no code fixes, so every finding stays open for the owner" (kept as the plan instructs); it contradicts the updated rows and is left for plan 11-24 to reconcile.
- The simulator system language is Polish; keys never use the localized description.

## Next

Ready for plan 11-13 (refreshed audit baseline). The owner sets `DP_RUN_A11Y_AUDIT=1` in the scheme Test action for that run (D11-26).

## Self-Check: PASSED

- Files: AccessibilityAuditSupport.swift, AccessibilityAuditUITests.swift, 11-EVIDENCE.md, 11-CONTEXT.md exist.
- Commits 72bbd30, a3610c7, ec62c6a are ancestors of HEAD; `git diff --name-only fc506f4` lists no path under `drinkpulse/`.
- Task verify commands: Task 1 ok, Task 2 greps ok with DEVLOG added lines only, Task 3 ok.
