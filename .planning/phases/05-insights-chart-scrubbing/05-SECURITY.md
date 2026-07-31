---
phase: 05
slug: insights-chart-scrubbing
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-07-31
---

# Phase 05 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Touch input → view-local selection state | The only input surface this phase introduces is a drag gesture handled entirely by the first-party `chartXSelection` API; `selectedKey`/`selectedLabel` is bounded to the plotted category keys already present in `data`/`bars` — no free-text/arbitrary input, no way to select a non-existent point. | UI-local selection state only, never persisted or transmitted |
| None (no network, no persistence, no auth) | `AXChartDescriptorRepresentable` conformances, `PointMark`/`RuleMark` marks, and `yDomainUpperBound` are all pure transforms over already-loaded, already-validated `[ChartPoint]`/`[WeekdayBar]` values — no new parsing of untrusted input. | None — display-only derivations |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-05-01 | Tampering | `selectedKey`/`selectedLabel` view-local `@State` | low | accept | Not persisted, not externally writable, resets naturally on view rebuild (D-07); worst case is a stale UI value corrected on next render. | closed |
| T-05-02 | Information Disclosure | Any `os.Logger` call near the selection state | low | mitigate | Verified: no `os.Logger`/`.log(` calls exist anywhere in `AlcoholAreaChart.swift`, `WeekdayBarChart.swift`, or `InsightsHeroCard.swift` — selected dates/grams are never logged. | closed |
| T-05-03 | Denial of Service | `chartXSelection` hit-testing against `activeDays`-scoped datasets | low | accept | Dataset size bounded by the existing Insights aggregation (already capped per period/all-time range); no new unbounded loop introduced. | closed |
| T-05-04 | Information Disclosure | `AXChartDescriptor` value-description closures | low | mitigate | Verified: `AlcoholAreaChart+Accessibility.swift` uses the injected `formattedValue` closure directly (line 27); `WeekdayBarChart+Accessibility.swift` uses the identical `unitDivisor`/`unitLabel` + `String(format: "%.1f", ...)` path as the visible per-bar `accessibilityLabel` (line 33) — neither hand-writes a separate formatting path. | closed |
| T-05-05 | Denial of Service | `makeChartDescriptor()` building `dataPoints` from `data`/`bars` | low | accept | Bounded by the same activeDays-limited aggregation scope; empty-array test cases prove the zero-element path doesn't crash. | closed |
| T-05-06 | Tampering | `yDomainUpperBound` computed from in-memory `data`/`bars` | low | accept | Pure derived display value, not persisted or externally writable; a wrong value at worst mis-renders spacing, never corrupts data. | closed |
| T-05-07 | Denial of Service | `data.map(\.grams).max()` / `bars.map(displayValue).max()` per render | low | accept | Bounded by the same capped aggregation scope; `max(peakValue * 1.6, 1)` floor guards a degenerate zero/empty-collection result. | closed |
| T-05-08 | Tampering | `PointMark`/`RuleMark` values derived from in-memory `data`/`bars` | low | accept | Pure derived display marks, not persisted or externally writable; a wrong mark position at worst mis-renders, never corrupts data. | closed |
| T-05-09 | Information Disclosure | `DPChartCalloutBackgroundModifier` in `DPGlass.swift` | low | accept | Purely a visual background (color/stroke/shadow); renders the same already-on-screen date/value text with an opaque box instead of a glass one — no new data surfaced. | closed |

*Status: open · closed · open — below {block_on} threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-05-01 | T-05-01, T-05-03, T-05-05, T-05-06, T-05-07, T-05-08, T-05-09 | All low-severity, no network/persistence/auth boundary crossed — chart scrubbing is a pure display feature over already-validated in-memory data. Individually assessed and accepted per-plan at authoring time (05-01 through 05-04 `<threat_model>` blocks). | gsd-planner (per-plan, at authoring time) | 2026-07-31 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-31 | 9 | 9 | 0 | orchestrator (L1 short-circuit — register authored at plan time, ASVS L1, threats_open: 0; mitigate-disposition threats T-05-02/T-05-04 independently verified via grep before short-circuiting per `secure-phase.md` Step 3) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-31
