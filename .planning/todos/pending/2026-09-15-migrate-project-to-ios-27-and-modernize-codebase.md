---
created: 2026-09-15T10:36:04.081Z
title: Migrate project to iOS 27 and modernize codebase
area: general
severity: major
resolves_phase: 08
files:
  - drinkpulse.xcodeproj/project.pbxproj:283
  - drinkpulse/
---

## Problem

The user wants a project-wide migration to iOS 27, with iOS 27 as the minimum supported version, plus modernization of the existing codebase and resolution of deprecated API usage. The current Xcode project declares IPHONEOS_DEPLOYMENT_TARGET = 26.0 in multiple configurations. Raising the deployment target alone does not cover the requested modernization.

Original request (Polish): „musimy zrobić migrację projektu do iOS 27 i ustawić iOS 27 jako minimalną wersję oraz zastosować najnowsze rozwiązania w miejsce starych, zaktualizować codebase i naprawić deprecations itd”.

## Solution

Plan and implement a full migration:

- Verify the appropriate Xcode/iOS 27 SDK and official Apple migration guidance at implementation time; identify relevant API replacements from documentation and compiler diagnostics.
- Set the minimum iOS deployment target to 27.0 consistently across the app, test targets, and all relevant build configurations. Align build tooling and project documentation.
- Audit the whole codebase for deprecated APIs, outdated patterns, and compatibility branches or workarounds made obsolete by the new minimum version.
- Replace obsolete implementations with suitable current APIs and recommended patterns, including relevant SwiftUI, persistence, concurrency, and system integrations. Document concrete replacements and their rationale during planning.
- Resolve deprecation warnings rather than suppressing them. Check dependency compatibility and update dependencies where needed.
- Verify Debug and Release builds and relevant automated tests on iOS 27. Check core user flows, persistence of existing user data, notifications, accessibility, and UI behavior for regressions.

Acceptance: all relevant targets require iOS 27 or later; the project builds with the selected compatible toolchain; deprecated API usages are replaced or individually documented if externally blocked; modernization is reviewed across the codebase; existing data and core app behavior remain correct.

## Update 2026-11-09 (Phase 10 carry-forward note, not closed)

This todo was folded into Phase 10 but spans the whole milestone, so it stays pending. Phase 10
delivered its data, persistence, services and concurrency slice (no personal values below):

- MOD-03 concurrency audit: the C010, C011 and C012 records are in `10-CONCURRENCY-RECORD.md`; the
  C008 and C009 dispositions and the gate results (zero-warning build, Thread Sanitizer shown
  active by a canary and then clean over 21 suites, schema and CloudKit-off guards, full suite 678
  unit and 93 UI tests, 94.61 percent overall coverage) are in `10-EVIDENCE.md`.
- `HealthKitAdapter` no longer carries an unchecked Sendable qualifier (plan 10-07).
- Owner decisions as their briefs record them: F2 `fix-query-first` (applied in plan 10-08), F3
  `fix-service-epoch+handler-sendable` (applied in plan 10-09), F4 weekly copy `as-of-last-visit`
  (applied in plan 10-10).
- Device session by category (`10-DEVICE-SESSION.md`): in-place upgrade of the real store, import
  round trip and Apple Health write, edit, delete all PASS; backgrounded reminder tap PASS;
  killed-app reminder tap FAIL (recorded in `10-DECISION-DEVICE-FINDING.md`, owner decision
  pending); detached cold-launch timing near container-load time, so the cold-launch todo is closed.

Remaining: the interface slice was Phase 09 (complete). The deprecation-diagnostics closure and
release verification belong to Phase 11 (MOD-04, VER-01 to VER-03), where this todo should be closed.
