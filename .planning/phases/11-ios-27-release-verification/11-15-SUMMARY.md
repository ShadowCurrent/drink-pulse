---
phase: 11-ios-27-release-verification
plan: 15
subsystem: accessibility
tags: [accessibility-audit, xcuitest, test-hook, gap-closure, a11y-audit-g08]
requires: [11-14]
provides:
  - shared ungated audit helper (pinAppearance, assertNoAuditIssues, assertNoAuditIssuesWhileScrolling, assertNoAuditIssuesOnProbes) for plans 11-16 to 11-21
  - History dynamicType audit tests at standard and AX5 (red before the fix, green after)
  - probe-only audit tests (Home, History calendar) that fail on any finding of any audit type on a test-only probe element
  - dp_health_sample_count as a one point non-text accessibility element
affects: [11-16, 11-17, 11-24]
tech-stack:
  added: []
  patterns: ["audit hook elements are one point Color.clear accessibility elements, never Text", "type-independent probe query: descendants(matching: .any).matching(identifier:)"]
key-files:
  created:
    - drinkpulseUITests/Features/History/HistoryAccessibilityAuditUITests.swift
    - drinkpulseUITests/Features/Shell/ProbeAccessibilityAuditUITests.swift
  modified:
    - drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift
    - drinkpulse/Features/Shell/RootShellView.swift
    - drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift
key-decisions:
  - "G08 is fixed on the test hook, not by muting the audit: the 1 point Text becomes a Color.clear 1x1 element with label = count"
  - "The probe-only helper is the single scoped assertion; it filters by element identifier only, takes its types from the caller and complements the unfiltered per-screen classes"
requirements-completed: []  # VER-03 and VER-01 are not completed by this plan; plan 11-24 and the phase reconciliation own requirement status
status: complete
commits: 2
plan_head_before: 1ccfcd0ca515af5d6ab5c21ccb7e534e25bf6a9a
plan_head_after: 41673022b9a926412dbf6c6d947d14d77367292b
actuals:
  tokens: 2800
  tasks: 2
  commits: 2
duration: 12 min
completed: 2026-11-16
---

# Phase 11 Plan 15: Close audit group G08 and add the shared audit helper Summary

The test-only Health sample-count overlay is now a one point `Color.clear` accessibility element (identifier `dp_health_sample_count`, label = count) instead of a 1 point text, which closes audit group A11Y-AUDIT-G08, and the shared ungated audit helper that plans 11-16 to 11-21 use now exists, proven red then green by a History audit test.

## Accomplishments

- **Task 1 (tracer, commit d514f31):** `AccessibilityAuditSupport.swift` gained `pinAppearance(_:)`, `assertNoAuditIssues(in:types:screen:variant:)` and `assertNoAuditIssuesWhileScrolling(in:types:screen:variant:maxPages:)`. Each passes the caller's types to `performAccessibilityAudit(for: types)`, records one `XCTFail` per issue in the key format `screen=<s> variant=<v> type=<t> element=<key>`, and returns true from the handler after recording. No allow-list, no type exclusion. `HistoryAccessibilityAuditUITests` (standard and AX5, `[.dynamicType]`) failed on `element=dp_health_sample_count` for both variants: group G08 is real and detectable.
- **Task 2 (commit 4167302):** `assertNoAuditIssuesOnProbes(in:types:requiredIdentifiers:identifierPrefixes:screen:variant:)` first fails for every missing required probe, then audits and fails only on issues whose element identifier starts with a probe prefix (`dp_motion.`, `dp_health_sample_count`). `ProbeAccessibilityAuditUITests` (Home, History calendar, `.all`) was red first on `element=dp_health_sample_count` only (Home: dynamicType; calendar: contrast and dynamicType); every required probe, `dp_motion.overviewBar`, `dp_motion.heroArc` and `dp_motion.historyCalendar` included, existed and none of the `dp_motion.*` probes had a finding, so step 4 (DPMotionProbe change) was not needed. `RootShellView` then replaced the 1 point `Text` with `Color.clear.frame(width: 1, height: 1).accessibilityElement(children: .ignore)` plus identifier and a `String` label, still inside the `UITestSeed.isActive` overlay. `HealthWriteHooksUITests` reads the probe through one private `healthSampleProbe` property (`descendants(matching: .any).matching(identifier:)`).

## Evidence (stamp directory `~/Library/Logs/DrinkPulse/phase-11-ios27/20261114T121519Z`)

| File | Run | Result |
| ---- | --- | ------ |
| `g08-red.result.txt` | HistoryAccessibilityAuditUITests, before fix | 2 failed, `element=dp_health_sample_count` |
| `g08-probes-red.result.txt` | ProbeAccessibilityAuditUITests, before fix | 2 failed, `element=dp_health_sample_count` only |
| `g08-green-audit.result.txt` | HistoryAccessibilityAuditUITests, after fix | 2 passed, 0 failed |
| `g08-probes-green.result.txt` | ProbeAccessibilityAuditUITests, after fix | 2 passed, 0 failed |
| `g08-health-hooks.result.txt` | HealthWriteHooksUITests | 4 passed, 0 failed |
| `g08-shell.result.txt` | ShellNavigationUITests | 4 passed, 0 failed |

Each file is the Xcode MCP JSON counts line, a short result block and the full MCP test summary. All runs used Xcode MCP only (workspace resolved with `XcodeListWorkspaces`, identifier not stored). `BuildProject buildForTesting` succeeded; `GetBuildLog` at warning severity returned 0 entries after fixing one unused-result warning in the first helper draft (see Deviations); `XcodeRefreshCodeIssuesInFile` returned 0 diagnostics for all five changed files.

## Verification

- Plan verify commands for Task 1 and Task 2 both ended with `ok`.
- Production files changed since `fc506f4` are the seven allowed ones (`DPMotion`, `DPMotionProbe`, `DPArcProgress`, `UITestSeed`, `ConsumptionOverviewCard`, `HistoryCalendarView`, `RootShellView`); this plan added only `RootShellView`. `DPMotionProbe.swift` was not changed.
- Shipped schema guard (`git diff --quiet fbd37fa` on `Schemas` and `MigrationPlan.swift`) exits 0; no production Swift file exceeds 300 lines.
- T-11-51: `dp_health_sample_count` appears once in `drinkpulse/` (`RootShellView.swift`), inside the `UITestSeed.isActive` overlay. T-11-52: the unfiltered helpers hard-code no type or filter; `assertNoAuditIssuesOnProbes` is the one identifier-scoped helper and both its callers pass `.all`.

## Apple API record

Read with Xcode MCP `DocumentationSearch` (XCTest and XCUIAutomation frameworks, SwiftUI):

| Page | Availability and facts used | Rationale |
| ---- | --------------------------- | --------- |
| `XCUIAccessibilityAuditType` (XCUIAutomation) | struct; option set used as `[.dynamicType]` and `.all` | audit types are caller-supplied |
| `XCUIAccessibilityAuditIssue` (XCUIAutomation) | `element: XCUIElement?`; `auditType` used by `AccessibilityAuditKey` | element identifier selects probe findings |
| `XCUIApplication.performAccessibilityAudit(for:_:)` | the page itself was not returned by search (only the type and issue pages); signature follows the existing, already-compiled use in `AccessibilityAuditUITests` and the iOS SDK header | handler returns true after `XCTFail` so no second failure is recorded |
| `View.accessibilityElement(children:)` (SwiftUI) | `.ignore`: "A new accessibility element is always created", children hidden, no initial properties | probe is a single element with no children |
| `accessibilityIdentifier(_:)` and `accessibilityLabel(_:)` (SwiftUI) | identifier identifies the view; label overload with a `String` used (typed `String`, so the value is not a localized key) | probe identity and count |
| `XCUIElementQuery` `descendants(matching:)` and `matching(identifier:)` (XCUIAutomation) | `matching(identifier:)` matches any of identifier, title, label, value, placeholderValue | type-independent probe query; `firstMatch` for a single element |
| `XCUIDevice.appearance` (XCUIAutomation) | get/set `XCUIDevice.Appearance` (`unspecified`, `light`, `dark`) | `pinAppearance` restores the read value, `.light` when unspecified |

No API was deprecated or replaced by this plan; it only adopts the documented modifiers.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unused-result warning in the first helper draft**
- **Found during:** Task 1 build
- **Issue:** `recordAuditIssue` returned Bool and `assertNoAuditIssues` ignored it: "Result of call to 'recordAuditIssue(...)' is unused" (zero-warning gate).
- **Fix:** `recordAuditIssue` returns Void; each handler returns `true` explicitly after recording.
- **Files modified:** `drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift`
- **Commit:** d514f31 (fixed before the first commit)

**Total deviations:** 1 auto-fixed (1 bug). **Impact:** none on scope.

Notes that are not deviations: `assertNoAuditIssuesWhileScrolling` looks for a scroll container among `scrollViews`, `collectionViews` and `tables` (plan named only `scrollViews`); a SwiftUI `List` is not guaranteed to surface as a scroll view. The helper is not used by this plan's tests; plans 11-16 to 11-21 own its use. Commit messages carry no AI attribution, per AGENTS.md.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path, file access or schema change.

## Ledger

The G08 row in `11-DEBT-LEDGER.md` is not edited here; plan 11-24 reconciles it from this SUMMARY (red `g08-red` and `g08-probes-red`, green `g08-green-audit` and `g08-probes-green`).

## Self-Check: PASSED

- Files exist: AccessibilityAuditSupport.swift, HistoryAccessibilityAuditUITests.swift, ProbeAccessibilityAuditUITests.swift, RootShellView.swift, HealthWriteHooksUITests.swift, six `g08-*.result.txt` files.
- Commits d514f31 and 4167302 are ancestors of HEAD.
