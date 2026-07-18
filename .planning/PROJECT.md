# DrinkPulse

## What This Is

DrinkPulse is a privacy-first iOS app for tracking personal alcohol
consumption and comparing it against international health guidelines
(WHO, DE, UK, US, AU, CA, or a custom limit). It requires no account, is
fully usable offline, and never sends data off the device unless the user
opts into their own iCloud sync. iPhone is the primary target (minimum
deployment iOS 26); iPad and an Apple Watch companion are planned for
later.

## Core Value

Every logged drink and every guideline comparison stays accurate and
private — on-device by default, with no account ever required.

## Requirements

### Validated

<!-- Shipped prior to GSD adoption. Delivered across 36 completed plans
     (docs/plans/0001–0036); see docs/plans/INDEX.md for the full delivery
     history. Requirements below were extracted from the now-retired
     docs/product.md and docs/roadmap.md (superseded by this file and
     .planning/ROADMAP.md as of 2026-07-18; see .planning/INGEST-CONFLICTS.md
     for the historical extraction record). -->

- ✓ REQ-quick-log-drink — Log a drink by type, volume, and strength (Add Drink flow v2)
- ✓ REQ-log-multiple-servings — Log multiple servings at once via a count multiplier (plan-0025)
- ✓ REQ-backdate-entry — Back-date an entry to yesterday or earlier
- ✓ REQ-optional-price — Optional price per entry, with currency (plan-0034)
- ✓ REQ-today-vs-guideline — Today's intake vs weekly guideline (Dashboard progress bars)
- ✓ REQ-history-by-day — Browse history grouped by day (History screen; plan-0013 calendar view)
- ✓ REQ-units-and-grams-per-entry — Alcohol units and pure-alcohol grams shown per entry
- ✓ REQ-sex-and-age-setting — Set biological sex and date of birth (plan-0009)
- ✓ REQ-guideline-choice-setting — Choose WHO / DE / UK / US / AU / CA / custom guideline (plan-0028 adds AU/CA)
- ✓ REQ-volume-unit-preference — Preferred volume unit: ml / US fl oz / Imperial fl oz (plan-0030, plan-0031)
- ✓ REQ-alcohol-display-unit-preference — Display unit: grams / standard drinks (UK reads "units") (plan-0029, ADR-0006)
- ✓ REQ-abv-precision-setting — ABV picker precision: 0.1% or 0.5%
- ✓ REQ-currency-preference-and-override — Preferred currency + per-drink override (plan-0034)
- ✓ REQ-first-launch-onboarding — 4-step skippable onboarding incl. optional Health opt-in (plan-0009, plan-0036)
- ✓ REQ-apple-health-writeback — Opt-in, off-by-default Apple Health write-back, dedup by UUID (plan-0036, ADR-0011)
- ✓ REQ-insights-screen — Insights: area chart, weekday patterns, health metrics, guideline comparison (plan-0012)
- ✓ REQ-history-calendar-view — History calendar with clickable days, inline detail panel (plan-0013)
- ✓ REQ-edit-entry-name-notes-category — Edit entry: custom name, notes, category change (plan-0014)
- ✓ REQ-log-reminders — Opt-in daily log reminder notification (plan-0016, ADR-0008)
- ✓ REQ-risk-language-rename — "Low / Moderate / High Risk" language (plan-0015)

### Active

<!-- Current scope. Building toward these. -->

(None — v1.0 shipped in full prior to GSD adoption. Next milestone scope
is not yet defined; run `/gsd-new-milestone` to pull candidates from
`REQUIREMENTS.md` → v2 Requirements into active scope.)

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- React Native, Flutter, or a web frontend — stack is SwiftUI-only (CLAUDE.md); native iOS is the product
- Backend services beyond CloudKit — privacy-first, on-device-only architecture; no custom backend
- Third-party analytics, crash reporters, or ad/attribution SDKs — no telemetry ever leaves the device
- Login / account systems — "no account, ever" is a core product value
- AI-generated drink recognition from photos — explicitly excluded; natural-language text entry (v2 backlog, on-device only) is the only AI feature under consideration

## Context

- **Maturity**: this is not a greenfield start — DrinkPulse already has 36
  completed delivery plans (`docs/plans/0001`–`0036`) predating GSD
  adoption. This ingest backfills `.planning/` to reflect that reality;
  it does not re-plan already-shipped work.
- **Architecture**: SwiftUI + SwiftData, MVVM; views own data access via
  `@Query` / `@Environment(\.modelContext)`, view models are
  `@Observable @MainActor` and stateless w.r.t. persistence (ADR-0004,
  supersedes the repository-layer design in ADR-0003). Platform
  capabilities (notifications, HealthKit, file IO) sit behind a
  `Services/` layer of protocol-wrapped adapters (ADR-0008).
- **Domain model**: grams of pure alcohol is the sole unit of truth;
  standard drinks / UK units / BAC are always derived, never stored.
  Volume→mass density depends on display mode **and** guideline
  (ADR-0006, amending/superseding ADR-0005); physical mass (calories,
  future BAC) always uses 0.789 g/ml regardless of display mode.
- **Data safety posture**: an explicit `VersionedSchema` + `MigrationPlan`
  baseline is in place (ADR-0009); every model change must additionally
  stay CloudKit- and HealthKit-compatible even while both integrations
  are off (CLAUDE.md forward-compat rule, established during plan-0036).
- **Sync status**: CloudKit Phase A (CloudKit-ready schema — stable
  `uuid` identity, `modifiedDate` LWW clock, `UserProfileStore`
  singleton, `RecordDeduplicator`) shipped under ADR-0010; CloudKit
  itself stays **OFF**. Phase B (flip it on) is blocked on a provisioned
  iCloud container (paid Apple Developer account) plus an explicit
  one-way approval from the owner.
- **Apple Health**: write-back shipped (plan-0036, ADR-0011) — mirrors
  logged drinks to `numberOfAlcoholicBeverages`, deduplicated via a
  durable `dp_event_uuid` sample-metadata key; opt-in, off by default,
  best-effort/non-blocking.
- **Open threads** (owner decision pending, see
  `.claude/context/open-questions.md`): BAC formula/UI (needs explicit
  design approval before implementation — never build without it),
  multi-currency spend aggregation on the Dashboard, guideline-alert-card
  tap action.
- **In draft, not yet approved**: `docs/plans/0037-apple-watch-companion/`
  (today glance + quick-log, Watch Connectivity transport, phone =
  source of truth) exists as a draft plan — not frozen, not scoped into
  any GSD milestone yet.
- **Testing regime**: ≥90% overall coverage enforced (100% Domain, ≥90%
  view models, ≥85% services), plus a mandatory XCUITest for every
  user-facing feature. Outstanding: a full accessibility audit
  (VoiceOver, Dynamic Type up to AX5) is still 🗓 planned, not done.
- **Deployment target**: raised to iOS 26 on 2026-06-23 (66% adoption at
  decision time); the codebase is fully native Liquid Glass with no
  backward-compat shims.

## Constraints

- **Tech stack**: SwiftUI + SwiftData + CloudKit (via SwiftData's built-in
  integration) only — no UIKit unless unavoidable, no `ObservableObject`
  / `@Published` / `@StateObject`, no CoreData, no third-party DI or
  database. Non-negotiable per CLAUDE.md.
- **Platform**: iPhone first; minimum deployment iOS 26. iPad and an
  Apple Watch companion are later-phase targets, not yet built.
- **Privacy**: on-device only; the sole permitted network traffic is
  SwiftData's CloudKit sync (currently off); no analytics, crash
  reporters, or third-party SDKs; consumption events, notes, and body
  metrics are treated as health data — never logged, never leave the
  device.
- **Domain integrity**: grams of pure alcohol is the canonical unit;
  every other measure is derived and never stored as primary data;
  guideline limits stay in physical grams; BAC (when built) and calories
  must always use the physical density (0.789 g/ml), never the
  display-unit density.
- **Schema evolution**: SwiftData model shape changes require a new
  `VersionedSchema` + `MigrationStage` — amending an already-shipped
  schema version is forbidden (it has already cost real data once);
  every schema/model change must remain CloudKit- and HealthKit-ready.
- **Testing**: ≥90% overall test coverage (100% Domain, ≥90% view
  models, ≥85% services) plus a required UI test for every user-facing
  feature; below-threshold coverage blocks task completion.
- **File size**: 300-line hard ceiling per Swift file.
- **Reversibility**: CloudKit enablement, data deletion, and other
  outward-facing or destructive actions need explicit per-action owner
  approval; nothing is pushed to a remote without an explicit,
  in-message "push" instruction for that specific push.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| ADR-0001: SwiftData + CloudKit for persistence/sync | No custom backend; last-write-wins conflict resolution handled by SwiftData/CloudKit | ✓ Good — Phase A (CloudKit-ready schema) shipped; CloudKit itself still OFF pending Phase B approval |
| ADR-0002: `@Observable` over `ObservableObject` | Modern Observation framework; avoids `@Published`/`@StateObject` boilerplate under Swift 6 strict concurrency | ✓ Good |
| ADR-0003: MVVM with a repository layer | Superseded by ADR-0004 before the repository layer was ever built | — Superseded (historical record only, not active) |
| ADR-0004: `@Query` + stateless view models, no repository layer | Views own data access; view models stay pure/testable without owning a `ModelContext` | ✓ Good — current architecture |
| ADR-0005: Density depends on the display unit (3-case `AlcoholUnit`) | Superseded by ADR-0006 (2026-07-18) | — Superseded (historical record only, not active) |
| ADR-0006: Density depends on display mode **and** guideline (2-case `AlcoholUnit`) | Collapses `.units` into `.standardDrinks`; matches WHO/DE/UK/AU vs. US/CA standard-drink definitions exactly | ✓ Good — sole authoritative density rule |
| ADR-0007: Store the entered unit (`enteredUnit`) on each event | Serving names stay stable across future unit-preference switches | ✓ Good |
| ADR-0008: `Services/` layer for platform capabilities | Protocol-wrapped platform access (notifications, Health, file IO); testable via injected fakes | ✓ Good — pattern reused for `HealthService` |
| ADR-0009: Versioned schema baseline + migration plan | Explicit `SchemaV1` / `MigrationPlan` unblocks CloudKit and future migrations safely | ✓ Good |
| ADR-0010: CloudKit-ready identity (`uuid` + `modifiedDate` LWW) | Drops `.unique`, adds stable identity + LWW clock so CloudKit can be enabled later without a rewrite | ✓ Good — Phase A done, CloudKit OFF |
| ADR-0011: Apple Health write-back + device-local sample identity | Dedup via `dp_event_uuid` sample metadata; `healthKitUUID` is device-local only, never synced/exported | ✓ Good — shipped, opt-in, off by default |

---
*Last updated: 2026-07-18 after initial GSD doc ingest of the existing DrinkPulse codebase (v1.0 shipped pre-GSD, plans 0001–0036)*
