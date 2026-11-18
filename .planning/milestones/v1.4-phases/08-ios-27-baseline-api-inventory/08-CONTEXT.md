# Phase 08: iOS 27 Baseline & API Inventory - Context

**Gathered:** 2026-09-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish a reproducible iOS 27 baseline for the app and both test targets, then produce a complete, source-backed inventory of existing API uses, patterns, and platform workarounds. Phase 08 records and evaluates modernization candidates; Phases 09 and 10 implement approved UI and data/service changes, and Phase 11 verifies the release. The inventory explicitly includes relevant Swift 6.4 language, standard-library, concurrency, and testing improvements. Preserve existing behavior, accessibility, and data. A newer API or practice alone does not justify a rewrite.

</domain>

<decisions>
## Implementation Decisions

### Baseline evidence
- **D-01:** Use the installed Xcode 27 toolchain and a named iOS 27 simulator as the Phase 08 baseline. Capture Debug and Release builds and the full unit and UI test suite. Real-device behavior checks belong to the later verification phase.
- **D-02:** Record the exact commands, selected Xcode and Swift compiler versions, SDK and runtime, simulator identity, dependency state, result counts, and all diagnostics. Keep a committed summary and complete raw logs for comparison.
- **D-03:** Classify any baseline failure as app-owned, test-related, or environment-related. Preserve its evidence and assign remediation to the relevant later phase; a failing baseline does not silently become a passing one or expand Phase 08 into a general bug-fix phase.

### Inventory detail
- **D-04:** Use one entry per distinct API or implementation pattern, grouping repeated uses while listing every exact source location. Each candidate needs its change, retain, or externally-blocked disposition, official Apple or Swift source, availability, rationale, priority, and destination phase.
- **D-05:** Record an explicit no-candidate row for every reviewed production and test area, naming what was checked. Coverage includes app entry/startup, features, design system, domain, persistence, services, tests, and tooling.
- **D-06:** Retain uncertain platform workarounds pending evidence. State the behavior they protect and the iOS 27 reproduction or official guidance that would justify revisiting them. Do not classify lack of a documented replacement alone as an external block.
- **D-07:** Review Swift 6.4 capabilities and current official best practices across the codebase. Include a change candidate when the guidance is relevant and the change preserves existing behavior and data; avoid style-only churn or speculative rewrites. Phase 08 inventories and recommends these changes, with implementation routed to Phases 09 or 10 as appropriate.

### Swift toolchain and language mode
- **D-08:** Adopt the Swift 6.4 compiler bundled with the selected Xcode 27 toolchain and record its exact version in the baseline. Keep `SWIFT_VERSION = 6.0` as Swift 6 language mode unless toolchain verification establishes a different supported setting; `6.4` is the compiler release, not a request to set `SWIFT_VERSION` to `6.4`. Check all targets and configurations for language-mode consistency and record any justified exception.

### Substantial replacement decision gate
- **D-09:** A candidate needs a separate decision brief and owner scope discussion if it may alter user behavior, accessibility, persisted data, startup/lifecycle behavior, or system integration semantics, regardless of diff size. Routine, behavior-preserving replacements can be recommended through the inventory.
- **D-10:** Prepare a separate brief per substantial candidate; related candidates may be discussed together. Each brief includes current and proposed behavior, official source, availability, benefits, cost, alternatives, compatibility, data/accessibility risks, and a recommendation.
- **D-11:** Record the owner's outcome as approve, retain, or defer, with scope and reason. Only approved scope enters an execution plan. If a substantial candidate appears later in the milestone, pause only that affected rewrite for the same brief and discussion while unrelated approved work continues.

### Documentation and artifacts
- **D-12:** Update `README.md` and `CLAUDE.md` as living entry points for the selected iOS 27/Xcode 27/Swift 6.4 toolchain and build/test instructions. Find and correct stale iOS 26 or Xcode guidance in all active setup, build, and test documentation. Historical plans and ADRs remain dated records.
- **D-13:** Keep the dated inventory, source links, dispositions, and decision briefs in Phase 08 planning artifacts; link durable guidance from living docs. Commit the baseline summary, exact commands, log paths, and log hashes. Keep bulky raw logs as linked local artifacts outside Git.

### Folded Todos
- **Migrate project to iOS 27 and modernize codebase:** `.planning/todos/pending/2026-09-15-migrate-project-to-ios-27-and-modernize-codebase.md` is the originating request for the deployment-target migration, codebase-wide audit, deprecation handling, and regression verification. Phase 08 performs its baseline and inventory portion; implementation and final verification remain assigned to Phases 09–11.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before researching or planning.**

### Scope and project rules
- `.planning/ROADMAP.md` — Phase 08 goal, success criteria, and the Phase 09–11 handoff.
- `.planning/REQUIREMENTS.md` — PLAT-01, PLAT-02, MOD-01, MOD-05 and milestone boundaries.
- `.planning/PROJECT.md` — privacy and data invariants, confirmed Xcode 27 baseline, Apple-documentation rule, and owner discussion rule.
- `.planning/todos/pending/2026-09-15-migrate-project-to-ios-27-and-modernize-codebase.md` — original migration request and acceptance statement.
- `CLAUDE.md` — current architecture, official-documentation rule, accessibility, testing, and living-documentation conventions. Its iOS 26 references are pre-migration state to update, not a Phase 08 scope restriction.

### Existing architecture and prior findings
- `.planning/milestones/v1.3-phases/07-swiftui-list-performance-gesture-audit/07-CONTEXT.md` — prior List audit scope and known History workaround evidence; its iOS 26 restriction applied to Phase 07 only.
- `.planning/debug/resolved/history-scrollview-bugs.md` — History List/ScrollView behavior and revert history to re-evaluate on iOS 27.
- `.planning/debug/resolved/contextmenu-zoom-glitch.md` — Liquid Glass context-menu workaround evidence to re-evaluate on iOS 27.
- `docs/decisions/0009-versioned-schema-and-migration-plan.md` — shipped-schema immutability and migration discipline.
- `docs/decisions/0010-cloudkit-ready-identity-and-lww.md` — identity and deduplication invariants; CloudKit activation remains outside this milestone.
- `docs/decisions/0011-health-write-back-and-device-local-sample-identity.md` — HealthKit identity and write-back invariants.
- `docs/decisions/0012-onboarding-single-source-of-truth.md` — startup/onboarding authority rule.

### Official toolchain and language sources
- Apple Xcode 27 release notes: https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes — check the exact installed build and bundled Swift version.
- Apple Xcode requirements: https://developer.apple.com/xcode/system-requirements — Xcode 27 toolchain and platform requirements.
- Swift 6.4 release notes: https://www.swift.org/blog/swift-6.4-released/ — language and library changes to evaluate.
- Swift language-mode guidance: https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/enabledataracesafety/ — distinguishes Swift 6 mode from the compiler release.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `drinkpulse.xcodeproj/project.pbxproj` contains the app, unit-test, and UI-test target settings; audit all relevant Debug and Release deployment and Swift settings.
- Existing `drinkpulseTests/` and `drinkpulseUITests/` suites provide the full simulator regression baseline.
- `.planning/codebase/STACK.md`, `.planning/codebase/STRUCTURE.md`, and `.planning/codebase/CONCERNS.md` provide starting maps for the source inventory; verify them against current code because they predate this migration.

### Established Patterns
- The app uses SwiftUI, SwiftData, Charts, UserNotifications, HealthKit, and Swift 6 strict concurrency, with no third-party package dependencies reported in the current stack map.
- SwiftData has frozen V1–V4 schema snapshots and a migration plan. Raising the deployment target alone is not grounds for a new schema or destructive store recovery.
- History List and context-menu behavior has prior iOS 26 workaround evidence; re-test before recommending removal.

### Integration Points
- `README.md`, `CLAUDE.md`, and other active build/test docs contain toolchain guidance to update after the baseline is selected.
- `drinkpulse/Domain/Persistence/`, `drinkpulse/Services/`, `drinkpulse/Features/`, `drinkpulse/DesignSystem/`, and both test targets define the inventory coverage surface.

</code_context>

<specifics>
## Specific Ideas

The owner explicitly added Swift 6.4 and newer best practices to this milestone, provided changes preserve existing behavior and data. A recommendation must cite current official guidance and explain its concrete benefit; API age by itself is not evidence. The selected baseline is a named iOS 27 simulator with both configurations and the full unit and UI suite.

</specifics>

<deferred>
## Deferred Ideas

No new capability was added during discussion. The separately matched GSD branch-per-milestone workflow todo is outside this iOS migration; the notification cold-launch todo is already completed, and name-autocomplete scope belongs to future product work.

</deferred>

---

*Phase: 08-ios-27-baseline-api-inventory*
*Context gathered: 2026-09-16*
