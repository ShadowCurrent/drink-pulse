# Roadmap: DrinkPulse

**Milestone:** v1.4 iOS 27 Migration & Modernization
**Status:** Approved 2026-09-16
**Created:** 2026-09-16
**Source:** [PROJECT.md](PROJECT.md), [REQUIREMENTS.md](REQUIREMENTS.md), [research/SUMMARY.md](research/SUMMARY.md)

## Milestone Goal

Require iOS 27 across DrinkPulse, modernize existing implementations using official Apple Documentation, and verify that existing data and behavior remain intact.

## Phase Overview

| Phase | Name | Goal | Requirements | Dependencies |
|---|---|---|---|---|
| 08 | iOS 27 Baseline & API Inventory | Establish the iOS 27 build baseline and classify every modernization candidate using official Apple sources | PLAT-01, PLAT-02, MOD-01, MOD-05 | Phase 07 archived |
| 09 | SwiftUI & Design System Modernization | Apply justified interface changes while preserving navigation, chart, History, form and accessibility behavior | MOD-02 | Phase 08 |
| 10 | Data & Platform Integration Modernization | Apply justified domain/service/concurrency changes and prove persistence and integrations survive the upgrade | MOD-03, DATA-01, INT-01, INT-02 | Phase 08; coordinate with 09 on shared files |
| 11 | iOS 27 Release Verification | Close deprecation diagnostics and verify builds, core flows and accessibility on iOS 27 | MOD-04, VER-01, VER-02, VER-03 | Phases 09 and 10 |

## Phase 08: iOS 27 Baseline & API Inventory

**Status:** Complete 2026-11-08

**Goal:** Establish a reproducible iOS 27 baseline and a complete, source-backed inventory before selecting code changes.

**Requirements:** PLAT-01, PLAT-02, MOD-01, MOD-05

**Success criteria:**

1. Xcode reports iOS 27.0 minimum for the app and both test targets in every relevant configuration; installed SDK/runtime and dependency versions are recorded.
2. Debug and Release baseline diagnostics are captured, with each app-owned deprecation tied to an exact source location and Apple documentation or compiler availability information.
3. Every production and test area is reviewed; each candidate is recorded as change, retain or externally blocked, with source, availability, rationale and a no-change entry where appropriate.
4. Project build instructions and living platform documentation reflect the selected toolchain and target; the baseline build result and any blockers are recorded without hiding warnings.
5. Substantial replacement candidates have a reviewable decision brief: official source, current behavior, proposed API and availability, benefits, cost, alternatives, compatibility, data/accessibility risks and recommendation. The owner discusses scope before such a rewrite is put into an execution plan. Later discoveries use the same decision gate.

**Implementation notes:** Source review includes iOS/iPadOS 27 and Xcode 27 release notes matching the installed build, SwiftUI, SwiftData, concurrency, UserNotifications, HealthKit and Charts. Review existing workarounds against reproduced iOS 27 behavior before removal. Avoid a schema change solely for raising the deployment target.

**Plans:** 8/8 plans complete

- [x] 08-07-PLAN.md
- [x] 08-08-PLAN.md

**Wave 1**

- [x] 08-01-PLAN.md — Align target settings and capture the iOS 27 Debug, Release, dependency, and full test baseline.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 08-02-PLAN.md — Update living toolchain guidance and audit active setup, build, and test documentation.
- [x] 08-03-PLAN.md — Inventory app entry, SwiftUI features, design system, resources, and UI tests.
- [x] 08-04-PLAN.md — Inventory domain, persistence, services, concurrency, unit tests, and tooling.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 08-05-PLAN.md — Reconcile complete inventory coverage and prepare substantial-candidate decision briefs.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 08-06-PLAN.md — Record owner decisions and bound the Phase 09/10 handoff.

## Phase 09: SwiftUI & Design System Modernization

**Status:** Complete 2026-09-19

**Goal:** Update interface code where Phase 08 finds a documented, behaviorally appropriate replacement.

**Requirements:** MOD-02

**Plans:** 3/3 complete

- [x] 09-01-PLAN.md — Dashboard strict-concurrency remediation
- [x] 09-02-PLAN.md — Add Drink sheet-root dismissal migration
- [x] 09-03-PLAN.md — iOS 27 retain evidence for protected SwiftUI behavior

**Success criteria:**

1. Every Phase 08 SwiftUI/design-system candidate has a completed change/retain/blocked disposition with exact documentation and verification evidence; substantial rewrites have an owner-discussed decision brief before planning.
2. Navigation, tabs, sheets, forms, History list/calendar and Insights charts continue to render and respond correctly on iOS 27 in affected test flows.
3. Known chart and History workarounds are retained unless iOS 27 reproduction and a verified replacement support their removal.
4. Affected accessibility behavior, localization and Reduce Motion are verified with meaningful tests or explicit human checks.

## Phase 10: Data & Platform Integration Modernization

**Goal:** Modernize domain, persistence, services and concurrency where justified while preserving existing data and system behavior.

**Requirements:** MOD-03, DATA-01, INT-01, INT-02

**Success criteria:**

1. Phase 08 domain, persistence, service and concurrency candidates have documented dispositions and focused regression evidence; actor isolation and lifecycle changes are justified. Substantial rewrites, including later discoveries, have an owner-discussed decision brief before planning.
2. Legacy schema fixtures and an existing current store open on iOS 27 with event/template/profile content, UUID identity and stored values intact; no destructive reset is required.
3. Daily/weekly notification opt-in, scheduling, completed-week comparison and cold/warm tap routing pass relevant tests or explicit device checks.
4. HealthKit permission, opt-in, write, delete and UUID deduplication behavior pass relevant tests or explicit device checks; CloudKit remains disabled.
5. Any necessary model-shape change creates a new versioned schema and migration stage and proves the old-to-new path; previously shipped schemas remain immutable.

**Plans:** 14/14 plans complete
**Wave 1**
- [x] 10-01-PLAN.md — Prove V1, V2 and V3 stores migrate to V4 with every stored property and no recovery, and that the launch sweep merges nothing.
- [x] 10-02-PLAN.md — Add the warm-tap route seam, tap delivery through UITestNotificationCenter, a gated warm-launch UI test and route unit tests.
- [x] 10-03-PLAN.md — Prove backup fixture loading, then commit an owner-scrubbed real-shape export with a placeholder lint (owner-gated).
- [x] 10-04-PLAN.md — Inject time into the weekly scheduler, pin completed-week comparison, brief and decide the F4 copy approach (owner decision).
- [x] 10-05-PLAN.md — Pin the Health edit-then-delete orphan sample (F2), brief it and record the owner decision.
- [x] 10-06-PLAN.md — Pin the reminder and weekly cancel-while-scheduling race (F3), brief it and record the owner decision.
- [x] 10-07-PLAN.md — Pin Health ordering and notification opt-out guarantees, drop the HealthKitAdapter unchecked Sendable qualifier, start the concurrency record.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 10-08-PLAN.md — Apply the owner-decided F2 Health fix with regression and UI evidence, or record retain or defer.
- [x] 10-09-PLAN.md — Apply the owner-decided F3 lifecycle epoch (a superseded schedule never removes a later request; optional guard or handler change), or record retain or defer.
- [x] 10-10-PLAN.md — Apply the owner-approved weekly summary wording with literal-string tests and close the copy todo.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 10-11-PLAN.md — Prove Thread Sanitizer activation, run it on final code, complete C010 to C012 records, run the zero-warning, schema, CloudKit-off, full-suite and coverage (overall, Domain, Services) gates.

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 10-12-PLAN.md — Owner device session (store upgrade, import round trip, HealthKit, notification taps, detached launch timing), cold-launch todo closure, umbrella todo carry-forward and living-doc updates.

**Wave 5** *(gap closure, INT-01 cold-tap blocker; blocked on Wave 4 completion)*
- [x] 10-13-PLAN.md — Assign the notification delegate synchronously in drinkpulseApp.init (owner outcome sync-assign), add the log-only tap-kind and assignment-duration lines, regression tests, zero-warning and full-suite gates, living docs (automated tests cannot prove system delivery timing).

**Wave 6** *(gap closure; blocked on Wave 5 completion)*
- [x] 10-14-PLAN.md — Owner device re-test (three or more killed-app taps, one backgrounded tap, three detached launch timings, cold weekly tap or N/A), the only verification source for the fix; record or escalate and update living docs.

**Cross-cutting constraints:** <!-- gsd:generated -->
- Every applied change records its isolation and lifecycle reasoning, the official source and the regression evidence (D-13).

## Phase 11: iOS 27 Release Verification

**Goal:** Demonstrate a warning-clean, data-safe and accessible migration with recorded build and test evidence.

**Requirements:** MOD-04, VER-01, VER-02, VER-03

**Success criteria:**

1. App-owned deprecation warnings are resolved without suppression; any externally blocked warning has a source, impact and follow-up recorded.
2. Debug and Release builds and scoped then integrated regression suites pass on iOS 27; evidence records Xcode/compiler, SDK, destination and limitations.
3. Onboarding, startup/retry, add/edit/delete, History, Insights, settings and backup export/import complete with existing data preserved.
4. VoiceOver on both chart Audio Graphs, Reduce Motion, Dynamic Type through AX5, light/dark and Increase Contrast checks are recorded as passed or remain explicitly open; automated and human results are distinguished.
5. Final verification reconciles the three archived Phase 05 skipped chart checks and does not silently close unrelated verification debt. It confirms that all substantial modernization discoveries received a recorded analysis and discussion outcome.

## Requirement Coverage

All 13 requirements map to exactly one phase: Phase 08 (4), Phase 09 (1), Phase 10 (4), Phase 11 (4).

## Prior Milestones

- v1.1 Weekly Summary Notification — shipped 2026-07-21
- v1.2 Swift 6 + App-Target Hardening — shipped 2026-07-28
- v1.3 Native Feel, followed by Phase 07 List Performance & Gesture Audit — last phase completed 2026-08-04

---
*Approved 2026-09-16 with owner-requested discussion of substantial API replacements.*
