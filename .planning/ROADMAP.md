# Roadmap: DrinkPulse

## Milestones

- ✅ **v1.1 Weekly Summary Notification** — Phases 1-1.1 (shipped 2026-07-21)
- ✅ **v1.2 Swift 6 + App-Target Hardening** — Phases 2-3 (shipped 2026-07-28)
- ✅ **v1.3 Native Feel** — Phases 4-6 (shipped 2026-07-31)

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)
- Phase numbers continue across milestones — v1.1 used 1 and 01.1; v1.2 used 2-3; v1.3 used 4-6 (never restart at 01)

<details>
<summary>✅ v1.1 Weekly Summary Notification (Phases 1-1.1) — SHIPPED 2026-07-21</summary>

- [x] Phase 1: Weekly Summary Notification (5/5 plans) — completed 2026-07-20
- [x] Phase 01.1: Address tech debt: weekly summary notification (1/1 plan) — completed 2026-07-21

Full detail: `.planning/milestones/v1.1-ROADMAP.md`

</details>

<details>
<summary>✅ v1.2 Swift 6 + App-Target Hardening (Phases 2-3) — SHIPPED 2026-07-28</summary>

- [x] Phase 2: Swift 6 Language Mode Migration (2/2 plans) — completed 2026-07-27
- [x] Phase 3: App Startup Hardening (2/2 plans) — completed 2026-07-28

Full detail: `.planning/milestones/v1.2-ROADMAP.md`

</details>

<details>
<summary>✅ v1.3 Native Feel (Phases 4-6) — SHIPPED 2026-07-31</summary>

- [x] Phase 4: Branded Static Launch Screen (1/1 plan) — completed 2026-07-30
- [x] Phase 5: Insights Chart Scrubbing (4/4 plans) — completed 2026-07-31
- [x] Phase 6: History List↔Calendar Directional Transition (1/1 plan) — completed 2026-07-31

Full detail: `.planning/milestones/v1.3-ROADMAP.md`

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|-----------------|--------|-----------|
| 1. Weekly Summary Notification | v1.1 | 5/5 | Complete | 2026-07-20 |
| 01.1. Address tech debt | v1.1 | 1/1 | Complete | 2026-07-21 |
| 2. Swift 6 Language Mode Migration | v1.2 | 2/2 | Complete | 2026-07-27 |
| 3. App Startup Hardening | v1.2 | 2/2 | Complete | 2026-07-28 |
| 4. Branded Static Launch Screen | v1.3 | 1/1 | Complete | 2026-07-30 |
| 5. Insights Chart Scrubbing | v1.3 | 4/4 | Complete | 2026-07-31 |
| 6. History List↔Calendar Directional Transition | v1.3 | 1/1 | Complete | 2026-07-31 |
| 7. SwiftUI List Performance & Gesture Audit | v1.3 | 5/5 | Complete | 2026-08-04 |

### Phase 7: SwiftUI List Performance & Gesture Audit

**Goal:** Every `blocker` and `worth-fixing` finding from the read-only List/gesture audit
(`07-RESEARCH.md`) is closed in code, each pinned by an automated `xcodebuild test` case — the
History row has one definition instead of two diverged copies, destructive delete is confirmation-
gated, rows carry stable identity and plain-data inputs, and section building leaves the render path.

**Requirements**: A1-1, C13-1 (blockers); A4-1, A4-2, A6-1, A7-1, A7-2, B8-1, B9-1, B10-1, C14-1,
C14-2, C14-3, C14-4, C14-7 (worth-fixing); A1-2, A1-3, A2-1, A3-2, A4-3, A6-2, B8-2, B9-2, C12-1,
C14-5, C14-6 (nits). Excluded and flagged: A3-1 (needs `SchemaV5` + `MigrationStage` — own phase or
accepted-and-deferred, per decision D-04), B9-3 (visual conversion, per decision D-05), L1 (iOS 27),
A6-3 (no action), X1/X2/X3 (doc contradictions, out of scope per CONTEXT).

**Depends on:** Phase 6
**Plans:** 5/5 plans complete

Plans:
**Wave 1**

- [x] 07-01-PLAN.md — Owner decisions (D-01..D-05) + the two blockers: stable row identity and confirmation-gated context-menu Delete
- [x] 07-02-PLAN.md — Pure value types: `RowUnitContext`, `EventRowStrings`, `DaySection` + `daySections(_:now:calendar:)`

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 07-03-PLAN.md — `EventRow` becomes plain-data and AX5-safe; extract `EventRowButton`; explicit accessibility actions
- [x] 07-04-PLAN.md — `GuidelineChoice.selectable` + shared `GuidelineChoiceRow` with the selected-state trait

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 07-05-PLAN.md — Cache day sections with midnight-safe refresh; shared row chrome; empty-window loading state

---
*Last updated: 2026-08-04 — Phase 7 complete: 5/5 plans executed, UAT 5/5 passed, security threat register closed (26/26). All blocker and worth-fixing findings from the List/gesture audit closed in code.*
