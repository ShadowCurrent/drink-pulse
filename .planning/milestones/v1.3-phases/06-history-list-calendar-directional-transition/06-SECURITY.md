---
phase: 06
slug: history-list-calendar-directional-transition
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-07-31
---

# Phase 06 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Segmented-control tap → view-local transition/direction state | The only new input this plan introduces is a `Picker` selection change routed through `selectSegment(_:)`; the resulting `insertionEdge`/`segment` values are bounded to `HistorySegment`'s two cases and `Edge`'s two used cases (`.leading`/`.trailing`) — no free-text or arbitrary input, no way to select a non-existent segment. | View-local `@State` only |
| None (no network, no persistence, no auth) | Reads already-validated, already-in-memory `ConsumptionEvent`/`UserProfile` data via unmodified `@Query`s; writes no new persisted or transmitted data. | None |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-06-01 | Tampering | `insertionEdge`/`segment` view-local `@State` | low | accept | Not persisted, not externally writable, resets naturally on view rebuild; worst case is a momentarily wrong slide direction, never a data-integrity issue, self-corrects on the next tap. | closed |
| T-06-02 | Information Disclosure | Any future `os.Logger` call added near `selectSegment`/direction debugging | low | mitigate | Captured in plan's `must_haves.prohibitions` and CLAUDE.md logging directive — no `ConsumptionEvent`/health-data values logged near this transition. Confirmed in SUMMARY: no `os.Logger` calls added near `selectSegment`/direction logic. | closed |
| T-06-03 | Denial of Service | Rapid/alternating segment taps driving repeated `HistoryListQueryView` `@Query` remounts | low | accept | Bounded by human tap rate and the existing, unmodified `listWindowStart`/`hasMoreToLoad` fetch window; no unbounded loop or recursive structure introduced. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on (high) count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-06-01 | T-06-01 | View-local state, self-corrects on next tap, no data-integrity impact. | plan author (06-01-PLAN.md threat model) | 2026-07-31 |
| R-06-02 | T-06-03 | Bounded by human tap rate and existing fetch-window logic; no unbounded work introduced. | plan author (06-01-PLAN.md threat model) | 2026-07-31 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-31 | 3 | 3 | 0 | /gsd-secure-phase (short-circuit: register authored at plan time, threats_open: 0, ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-31
