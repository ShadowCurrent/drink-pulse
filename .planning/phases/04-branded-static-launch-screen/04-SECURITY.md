---
phase: 04
slug: branded-static-launch-screen
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-31
---

# Phase 04 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| None applicable | Phase changes only static, build-time Info.plist/build-setting config and two Asset Catalog entries (compiled on-device by Xcode's asset compiler). No network call, no user input, no persisted user/health data. | None |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-04-01 | Tampering | `drinkpulse.xcodeproj/project.pbxproj` build-setting edit | low | accept | Local, git-tracked config change reviewed via normal commit diff before merge; a wrong key silently falls back to the pre-existing blank launch screen (a visual regression, not a security exposure) — no attacker-reachable runtime surface. | closed |
| T-04-02 | Information Disclosure | `LaunchIcon`/`LaunchBackground` Asset Catalog entries | low | accept | Both assets are derived from the already-public Home Screen `AppIcon` and a plain system background color — no information exposed beyond what the Home Screen icon already shows publicly. | closed |

*Status: open · closed · open — below {block_on} threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| R-04-01 | T-04-01 | Low-severity, no attacker-reachable runtime surface; accepted at plan time. | plan (04-01-PLAN.md) | 2026-07-29 |
| R-04-02 | T-04-02 | Low-severity, no new information exposed beyond existing public Home Screen icon; accepted at plan time. | plan (04-01-PLAN.md) | 2026-07-29 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-31 | 2 | 2 | 0 | gsd-secure-phase (short-circuit: threats_open=0, register_authored_at_plan_time=true, asvs_level=1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-31
