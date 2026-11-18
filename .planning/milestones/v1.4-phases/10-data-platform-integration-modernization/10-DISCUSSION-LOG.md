# Phase 10: Data & Platform Integration Modernization - Discussion Log

> **Audit trail only.** Do not use this log as input to planning, research or execution agents.
> Decisions are captured in CONTEXT.md. This log keeps the alternatives that were considered.

**Date:** 2026-11-08
**Phase:** 10-data-platform-integration-modernization
**Areas discussed:** Legacy-store fixtures, Concurrency proof bar, Device vs automated checks, Backup/export proof

---

## Todo folding

| Option | Description | Selected |
|--------|-------------|----------|
| Notification cold-launch | Debugger-detached re-measurement; close or escalate | ✓ |
| Weekly summary wording | Name both compared weeks in the notification copy | ✓ |
| iOS 27 migration umbrella | Phase 10 covers its data/integration slice | ✓ |

**User's choice:** All three were folded.

---

## Legacy-store fixtures

| Question | Options | Selected |
|----------|---------|----------|
| How to prove the legacy upgrade | Keep programmatic + extend / Add committed store files / You decide | Keep programmatic + extend |
| Current-store proof | Your device store / Simulator upgrade only / Both | Your device store |
| Field depth | Every stored field / Identity + key values | Every stored field |
| On defect | Stop and brief me / Fix if non-schema | Stop and brief me |
| Safety net before the device upgrade | Export backup first / No pre-step | Export backup first |
| Assert no recovery | Yes / Not needed | Yes |
| Dedup sweep on migrated stores | Yes / No | Yes |

**Notes:** Schema fix means a new SchemaV5 plus a MigrationStage. Shipped schemas stay immutable.

---

## Concurrency proof bar

| Question | Options | Selected |
|----------|---------|----------|
| Evidence bar | Compiler or TSan or repro / Compiler only / Compiler + mandatory TSan | Compiler or TSan or repro |
| Clean result | Retain record + new tests / Retain record only | Retain record + new tests |
| `@unchecked Sendable` sites | Re-justify, keep / Try to remove all | Re-justify, keep |

---

## Device vs automated checks

| Question | Options | Selected |
|----------|---------|----------|
| Warm tap routing | Add automated UI test / Device check only | Add automated UI test (plus device check) |
| HealthKit proof | Fakes + device check / Fakes + simulator HealthKit | Fakes + device check |
| Weekly wording | Name both weeks (all variants) / Only "down" | Name both weeks |
| Cold-launch todo | Device measure then close / Close without measuring | Device measure then close |

---

## Backup/export proof

| Question | Options | Selected |
|----------|---------|----------|
| Export fixture | Synthetic JSON fixtures / Existing tests enough / Sanitized real export | Sanitized real export |
| Device import round-trip | Yes / No | Yes |

**Notes:** The export is health data. It must be fully scrubbed, and the owner reviews it before commit (CONTEXT D-07).

## Claude's Discretion

- Test file layout
- How the recovery-not-fired assertion is exposed
- Scrubbing method
- TSan run granularity

## Deferred Ideas

None.
