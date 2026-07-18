# Requirements: DrinkPulse

**Defined:** 2026-07-18
**Core Value:** Every logged drink and every guideline comparison stays accurate and private — on-device by default, with no account ever required.

## v1 Requirements

Requirements for the current milestone. Each would map to a roadmap phase.

_No requirements are currently active for a new v1 milestone._

DrinkPulse's original v1.0 scope — logging, insight, settings, onboarding,
Apple Health write-back, risk-language, history calendar, in-place entry
editing, and log reminders (20 requirements total) — shipped prior to GSD
adoption, across `docs/plans/0001`–`0036`. See `PROJECT.md` → Requirements
→ Validated for the full list with shipped-plan references.

Next milestone scope is not yet defined. Run `/gsd-new-milestone` to pull
candidates from **v2 Requirements** below (or new ideas) into active v1
scope, then re-run roadmapping.

## v2 Requirements

Deferred to a future release. Tracked but not in the current roadmap.
Sourced from the 2026-05-19 design handoff and the pre-GSD `docs/roadmap.md`
idea backlog (superseded by this section).

### Health & Safety

- **BAC-01**: BAC estimate (Widmark formula), labeled as an estimate, not
  medical advice. Requires body weight input in Settings. **Gated**: per
  CLAUDE.md, propose the design and get explicit owner approval before
  implementing — do not build without it (see
  `.claude/context/open-questions.md` § BAC implementation).

### Spending

- **SPND-01**: Currency preference and a dedicated spending-tracker
  screen (spend is already surfaced inside the Insights card by design).

### Personalization

- **PERS-01**: Custom drink templates (user-created `DrinkTemplate`).

### Insights

- **INST-01**: Monthly trend charts beyond what the current Insights
  screen provides.

### Platform Expansion

- **PLAT-01**: Widget / Lock Screen Live Activity showing today's units.
- **PLAT-02**: Apple Watch quick-log glance — today summary + log drink,
  iOS app extension (not standalone watchOS); scope confirmed by owner
  2026-05-19. A **draft** plan already exists at
  `docs/plans/0037-apple-watch-companion/plan.md` (today glance +
  quick-log, Watch Connectivity transport, phone = source of truth) but
  is not yet frozen or scoped into a milestone.

### Engagement

- **ENGG-01**: Weekly summary notification.

### Smart Entry

- **SMRT-01**: AI natural-language drink entry — e.g. type "had a Tyskie
  at 9pm" and have the app parse it. On-device model preferred to
  preserve privacy (no data leaves the device).

### Export & Sharing

- **SHRE-01**: PDF export of Insights — formatted monthly summary for
  personal archive or sharing with a clinician.

### Platform & Performance

- **PLAT-03**: iPad layout (`NavigationSplitView`).
- **PERF-01**: SwiftData compound indexes — `#Index` macro on
  `ConsumptionEvent` for `(timestamp, category)`. Improves query
  performance as the event log grows.
- **PERF-02**: SwiftData History API — `HistoryDescriptor` for iCloud
  sync conflict resolution (replaces default last-write-wins). Evaluate
  together with the iCloud sync plan (ADR-0010).
- **PERF-03**: Dynamic `@Query` predicates — sort/filter as `@State`
  without rebuilding views. Unlocks history filtering by category or
  date range.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| React Native, Flutter, or a web frontend | Stack is SwiftUI-only (CLAUDE.md); native iOS is the product |
| Backend services beyond CloudKit | Privacy-first, on-device-only architecture; no custom backend |
| Third-party analytics, crash reporters, or ad/attribution SDKs | No telemetry ever leaves the device |
| Login / account systems | "No account, ever" is a core product value |
| AI-generated drink recognition from photos | Explicitly excluded (CLAUDE.md); SMRT-01's natural-language text entry is the only AI feature under consideration, and only on-device |

## Traceability

No requirement is currently mapped to an active roadmap phase — v1.0
shipped in full prior to GSD adoption (see `PROJECT.md` → Validated) and
no next-milestone scope has been defined yet.

| Requirement | Phase | Status |
|-------------|-------|--------|
| *(none active)* | — | — |

**Coverage:**
- v1 requirements: 0 total
- Mapped to phases: 0
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-18*
*Last updated: 2026-07-18 after initial GSD doc ingest of the existing DrinkPulse codebase*
