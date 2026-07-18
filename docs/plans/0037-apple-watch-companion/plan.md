# 0037 — Apple Watch companion (today glance + quick-log)

**Status**: draft
**Size**: large
**Created**: 2026-06-30

## Summary

A companion **watchOS app** (bundled with the iOS app, not standalone-only)
that lets the user:

- **See today at a glance** — a risk arc with today's total vs the daily
  limit, mirroring the Dashboard hero.
- **Quick-log a drink** — tap a recent/favorite `DrinkTemplate` to log it in
  one tap (optional quantity stepper). No full pickers on the watch.
- **Glance from the watch face** — a **complication** and a **Smart Stack
  widget** showing today's % of the daily limit.

**Transport is Watch Connectivity (`WCSession`)**, not CloudKit. The **phone
is the single source of truth**: the watch proposes new events, the phone
persists them to SwiftData. CloudKit stays OFF and is unaffected.

Read-back of edits/deletes from the watch is **out of scope** — the watch
only *appends* logs and *reads* today's snapshot.

## Context

- Open question "Apple Watch: data transport" (`open-questions.md`): shared
  CloudKit store vs Watch Connectivity relay. **Resolved here → Watch
  Connectivity now**, because CloudKit (plan-0023 Phase B) is gated on a paid
  Apple Developer account + provisioned container + one-way approval, and
  CloudKit propagation latency is too slow for a "log → see it" loop anyway.
- Memory (`project_future_apple_watch`): confirmed scope = today summary +
  log drink; companion to the iOS app, **not** a standalone watchOS product.
- Surfaces confirmed with owner (2026-06-30): watch app + complication +
  Smart Stack widget; transport = Watch Connectivity.

### Why Watch Connectivity fits the existing architecture

The watch mints a `uuid` for each logged event; the phone **upserts by
`uuid`** into SwiftData. This reuses the existing identity + LWW contract
(plan-0023 / ADR-0010): the watch is just another writer proposing events,
identical to import. `RecordDeduplicator` already guards duplicate `uuid`s.
No new conflict-resolution model, **no schema change, no migration** — the
watch reuses the phone's `@Model` types.

Because the watch only appends (no edit/delete), the phone remains the sole
mutator of stored events. There is nothing to reconcile beyond append.

## Scope

### In

- New **watchOS app target** (`DrinkPulse Watch App`), companion-bundled.
- New **watch widget extension** (complication + Smart Stack widget).
- New `Services/WatchConnectivityService` — protocol
  (`WatchSyncing`) + `WCSession` adapter + UI-test stub, same shape as
  `HealthService` / `ReminderService`. Lives on **both** targets (phone side
  receives events + pushes snapshots; watch side sends events + receives
  snapshots).
- Phone side: receive queued events → upsert `ConsumptionEvent` by `uuid`;
  push a **today-snapshot** (today grams, daily-limit grams, risk %, top-N
  templates) on data change and on `WCSession` activation.
- Watch side: render today gauge from the latest snapshot; show top-N
  templates; one-tap log (+ optional qty stepper) → enqueue event; optimistic
  local pending state when phone unreachable.
- On-watch snapshot persistence to a **watch-side app group** so the watch
  widget extension reads it (app groups work watch-app ↔ its-widget; same
  device).
- Unit tests (WC service logic, snapshot encode/decode, uuid-upsert
  idempotency on phone, pending-count math) + watch UI tests for the
  log + gauge flow.

### Out

- **Editing or deleting** events from the watch (phone-only).
- **CloudKit** on the watch (independent watch store) — deferred; the service
  protocol keeps it a future swap.
- Read-back of Health/other data on the watch.
- Standalone (iPhone-not-required) installation as a hard requirement — the
  watch degrades gracefully offline but its data round-trips through the phone.
- Insights/History/Settings on the watch.
- Any change to Domain calculations, schema, or the phone UI beyond the
  snapshot-push trigger.

## Transport design (propose — owner sign-off before freeze)

This section touches the sync boundary, so per CLAUDE.md it is a **proposal**;
do not implement until confirmed.

- **Watch → phone (log a drink):** `transferUserInfo(_:)`. Queued, guaranteed
  FIFO delivery even when the phone is asleep/unreachable, flushed in the
  background. Payload = a minimal event dict: `uuid`, template id (if any),
  `volumeMl`, `abv`, `quantity`, `enteredUnit`, `timestamp`, and the
  snapshot-relevant category/icon needed to reconstruct an ad-hoc event.
- **Phone receives:** decode → build/insert `ConsumptionEvent` with the
  watch-minted `uuid` → upsert (existing dedup path). Idempotent: re-delivery
  of the same `uuid` is a no-op.
- **Phone → watch (today glance):** `updateApplicationContext(_:)`. Latest-only,
  overwrites prior, delivered opportunistically in the background, available
  even if the watch app launches offline. Carries the today-snapshot.
- **Offline on watch:** logs enqueue via `transferUserInfo` (WC persists and
  flushes on reachability); the gauge updates **optimistically** with a local
  pending count + an "syncing" indicator until the next snapshot confirms.

## Decisions (to confirm with owner before freeze)

1. **Logging granularity** — one-tap from templates (recommended) + optional
   qty stepper, vs full detail pickers. _Proposed: one-tap + qty stepper._
2. **Template set on watch** — top-N most-recent / favorites pushed in the
   snapshot, vs all templates. _Proposed: top-N recent (small screen)._
3. **Complication content** — today % of daily limit + risk colour
   (matches Dashboard), vs remaining grams/drinks. _Proposed: % + risk colour._
4. **Optimistic update** — gauge reflects watch-side pending logs before the
   phone confirms. _Proposed: yes, with a pending indicator._
5. **App packaging** — companion-bundled (installs with phone app), not
   independently-installable-only. _Proposed: companion-bundled._

## Risks

- **No paid account on device** — the watch app builds and runs in the
  paired simulator with no paid account; on-device install needs a watch
  provisioning profile (same constraint as HealthKit). Dev/test unaffected.
- **WCSession lifecycle** — activation timing, `isReachable` vs background
  transfer semantics; covered by routing all WC through the injected protocol
  and faking it in tests (never call `WCSession.default` from view models).
- **Snapshot staleness** — mitigated by pushing on every relevant phone-side
  data change + on activation; watch shows a freshness/offline indicator.
- **Duplicate logs** — mitigated by uuid upsert (regression test required:
  watch event + later phone event with same uuid = one stored event).
- **Project structure** — new targets must keep the file-system-synchronized
  test layout; watch sources live in their own target folder.

## Steps (high level)

1. **Targets** — add `DrinkPulse Watch App` + watch widget extension; wire
   app groups (watch side); shared Domain/model code visible to the watch
   target.
2. **`WatchSyncing` protocol + adapters** — `WCSession` adapter (both sides) +
   UI-test stub; inject via environment, same pattern as `HealthService`.
3. **Snapshot model** — `Codable` today-snapshot value type (grams, limit,
   risk %, top-N templates); encode/decode + persistence to the watch app group.
4. **Phone side** — push snapshot on data change + activation; receive events
   → uuid upsert into SwiftData.
5. **Watch app UI** — today gauge (reuse risk arc styling) + template grid +
   one-tap log + qty stepper + offline/pending indicator.
6. **Watch widget** — complication + Smart Stack widget reading the snapshot
   from the app group; timeline refresh.
7. **Tests** — WC service logic, snapshot codec, uuid-upsert idempotency,
   pending math (unit); watch UI test for gauge + one-tap log flow.
8. **Docs** — architecture.md (new watch target + transport boundary),
   roadmap (✅), domain.md (no change expected — confirm), new **ADR-0012**
   (Watch Connectivity transport + phone-as-source-of-truth), open-questions
   (resolve the transport entry).

## Open questions

- Should the watch show **anything beyond today** (e.g. this-week ring)?
  Default: today only for v1.
- Complication families to support (corner / circular / inline / Smart Stack)
  — pick the set in step 6.
- Does a watch-logged ad-hoc drink (no template) need a name, or is
  category+volume enough? Default: category+volume (reuses `displayName`).

## Tests required

- **WatchConnectivityService** (≥85%): send/enqueue, receive→decode, snapshot
  push, activation, unreachable/queued paths — through the injected protocol.
- **Snapshot codec** (100%): encode/decode round-trip, top-N truncation,
  empty/zero-consumption snapshot.
- **Phone uuid-upsert idempotency** (regression): same `uuid` delivered twice
  → one stored event; watch event + phone event same `uuid` → one event.
- **Pending-count math** (100%): optimistic gauge before/after snapshot
  confirm.
- **Watch UI test**: launch → gauge reflects seeded snapshot → one-tap log →
  pending indicator appears. (watchOS UI test target.)
