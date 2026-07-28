# Requirements: DrinkPulse v1.2

**Defined:** 2026-07-27
**Core Value:** Every logged drink and every guideline comparison stays accurate and private — on-device by default, with no account ever required.

## v1 Requirements

Requirements for milestone v1.2 (Swift 6 + App-Target Hardening). Each maps to roadmap phases. Source: Cluster A of `.planning/todos/CLUSTERS.md` — own milestone, must not interleave with Cluster B (native feel).

### Swift 6 Migration

- [x] **SWIFT6-01**: App target builds clean under `SWIFT_VERSION = 6.0` (Debug+Release) with zero data-race errors/warnings
- [x] **SWIFT6-02**: Deprecated/soft-deprecated APIs surfaced by the language-mode flip are migrated
- [x] **SWIFT6-03**: Decision made and applied on the 2 remaining XCTest unit files (`HistoryViewModelTests`, `ScreenComputePerformanceTests`) — convert to Swift Testing or document as intentional legacy

### App Startup Hardening

- [x] **STARTUP-01**: Onboarding gate (`RootShellView`/`drinkpulseApp.swift`) has a single authoritative source of truth; a transient empty `@Query profiles` result no longer resets the user to onboarding mid-task
- [x] **STARTUP-02**: `sharedModelContainer` creation no longer blocks the synchronous `App.init` path
- [x] **STARTUP-03**: The two `fatalError` container-failure call sites (`drinkpulseApp.swift:59,68`) are replaced with a real, designed user-facing error state

## v2 Requirements

None deferred from this milestone — all Cluster A scope is in v1 above.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Cluster B (native feel: motion, layout, chart interaction) | Own milestone per `.planning/todos/CLUSTERS.md` — must not run during Cluster A |
| Insert-audit todo (`context.insert` missing-save sites) | Unclustered, outcome unknown — routed to `/gsd-quick` separately; may feed back into a future Cluster A follow-up if it finds real matches |
| App rename to DrinkPulse | Unclustered, isolated — routed to `/gsd-quick` separately |
| BAC estimate | Gated on explicit owner design approval, unrelated to this hardening scope |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SWIFT6-01 | Phase 2 | Complete (02-01) |
| SWIFT6-02 | Phase 2 | Complete (02-01) |
| SWIFT6-03 | Phase 2 | Complete (02-02) |
| STARTUP-01 | Phase 3 | Complete |
| STARTUP-02 | Phase 3 | Complete (03-02) |
| STARTUP-03 | Phase 3 | Complete (03-02) |

**Coverage:**

- v1 requirements: 6 total
- Mapped to phases: 6 (Phase 2: SWIFT6-01/02/03; Phase 3: STARTUP-01/02/03)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-27*
*Last updated: 2026-07-27 after roadmap creation — 6/6 v1 requirements mapped to Phase 2 (Swift 6 Language Mode Migration) and Phase 3 (App Startup Hardening)*
