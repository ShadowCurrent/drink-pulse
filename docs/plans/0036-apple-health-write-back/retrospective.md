# 0036 — Retrospective

**Completed**: 2026-06-29 · **Status**: completed

## What shipped

Opt-in, off-by-default Apple Health write-back. Logged drinks are mirrored to
`numberOfAlcoholicBeverages` (a drinks count = `pureAlcoholGrams / 14.0`); edits
rewrite and deletes remove the sample. Enable from Settings or a new onboarding 4th
step. Dedup is by a durable `dp_event_uuid` sample metadata key (read+write), so
reinstall / restore-to-new-device / multi-device never duplicate. `healthKitUUID` is
a device-local cache only (never exported/synced). Best-effort and non-blocking — a
Health failure never blocks the in-app log/edit/delete.

Delivered across 8 waves (W1 schema → W2 protocol/adapter → W3 service → W4 Settings
→ W5 hooks → W6 entitlement → W8 onboarding → W7 close-out), each its own commit:
`cc9436d, eb447c4, eb48b60, 02861d0, 473ffc7, 42b7ce6, a7a7339, <W7>`.

## What went well

- **Wave isolation.** One commit + one execution.md entry per wave kept the
  coordinator session's state clean and made verification cheap (each wave
  independently re-built/tested before moving on).
- **Schema discipline.** Froze `SchemaV3` into a snapshot + added `SchemaV4` +
  lightweight `v3→v4` per the no-amend rule; migration test pins it.
- **Dedup design.** `dp_event_uuid` metadata + read-for-dedup is self-verifying
  against the live Health store, so it survives the device-local nature of HKSample
  UUIDs that a stored id never could.

## What surprised us (and the corrections)

- **`dietaryAlcohol` does not exist.** The roadmap/plan/ADR premise was wrong;
  HealthKit only offers `numberOfAlcoholicBeverages` (count) and `bloodAlcoholContent`
  (BAC). Caught at W2 by the compiler + SDK headers. Resolved with the owner: write a
  fractional count at fixed 14 g/drink. Lesson: **verify framework type identifiers
  against the SDK before writing them into a plan**, especially for niche domains.
- **Read scope was unavoidable.** "Write-back" still needs read authorization to
  dedup against our own samples — surfaced and confirmed before coding the adapter.
- **App deletion does not delete Health data**, and Health has its own iCloud sync —
  both feed the dedup design (owner raised this; it tightened W2/W3).
- **UI-test tap artifact (W8).** A centre `XCUIElement.tap()` on a full-width
  *labelled* Toggle misses its interactive area (the Settings toggle is
  `.labelsHidden()` and narrow, so it worked). A one-line diagnostic proved the
  binding never fired — not a logic/env bug. Fixed by tapping a trailing-edge
  coordinate. Lesson: for labelled toggles, key UI-test taps off the control, not the
  element centre.

## Process notes

- One subagent (W8) hit a session limit mid-task; the coordinator finished it inline.
  The per-wave commit + execution.md journal made the half-done tree easy to pick up.
- W6 (entitlement) and W7 (close-out) were done inline: signing changes want care,
  and the close-out synthesis needs full cross-wave context (incl. the count
  correction) that a cold agent would re-derive.

## Gates at close

`xcodebuild build` clean (zero new warnings; HealthKit entitlement embeds + simulator
runs ad-hoc, no paid account needed). Full suite **TEST SUCCEEDED**, app coverage
**93.23%** (≥90%); `HealthService` logic 100%. No production file > 300. No PII logs,
no new network. All commits local — **not pushed**.

## Follow-ups (not in scope)

- Device install needs the HealthKit capability provisioned against a team; App Store
  needs the paid account.
- Reading alcohol data *from* Health (import) — explicitly out of scope here.
- The CloudKit Phase-B interaction (a synced event with no local sample → write fresh)
  is handled by the same dedup query; revisit when plan-0023 Phase B lands.
