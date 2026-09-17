---
phase: "08"
slug: "ios-27-baseline-api-inventory"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-17"
---

# Phase 08 — Security

## Trust Boundaries

| Boundary | Description | Data Crossing |
|---|---|---|
| Local Xcode and simulator evidence to committed docs | Build/test logs may contain sensitive fixture or signing information. | Sanitized metadata, hashes, paths |
| Source and Apple documentation to future modernization scope | An unsupported claim could authorize an unsafe change. | API availability and source citations |
| Owner decision to downstream phase scope | Proposed work must not become authorized without an explicit outcome. | Candidate ID, scope, and rationale |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|---|---|---|---|---|---|---|
| T-08-01 | Information disclosure | Baseline logs | high | mitigate | Raw logs outside Git; committed evidence is redacted path/hash metadata. | closed |
| T-08-02 | Tampering | Result attribution | medium | mitigate | Preserve original exit status, bundles, hashes, and classifications. | closed |
| T-08-03 | Repudiation | Full-suite scope | medium | mitigate | Record shared-scheme testables and available target-level evidence. | closed |
| T-08-04 | Tampering | Build instructions | medium | mitigate | Cross-check active docs against `08-BASELINE.json` and `08-DOC-AUDIT.md`. | closed |
| T-08-05 | Information disclosure | Documentation examples | low | mitigate | Do not embed raw logs or signing values in docs. | closed |
| T-08-06 | Tampering | UI inventory | medium | mitigate | Link each claim to source location and official documentation. | closed |
| T-08-07 | Denial of service | History workaround removal | medium | mitigate | Retain production behavior pending targeted reproduction and Phase 09 review. | closed |
| T-08-08 | Information disclosure | UI-test capture | high | mitigate | Use synthetic fixtures and keep raw artifacts outside Git. | closed |
| T-08-09 | Tampering | SwiftData schemas and persisted values | high | mitigate | Inventory-only scope; later migration needs a separate Phase 10 plan and owner brief. | closed |
| T-08-10 | Elevation of privilege | HealthKit and notification permissions | high | mitigate | Treat lifecycle/permission candidates as substantial; require owner decision before planning. | closed |
| T-08-11 | Information disclosure | Service diagnostics | medium | mitigate | Cite locations and IDs without copying health values. | closed |
| T-08-12 | Tampering | Candidate disposition | medium | mitigate | Reconcile all tracked paths and require source-backed classification. | closed |
| T-08-13 | Repudiation | Decision register | high | mitigate | One brief and outcome row per candidate; no scope authorization before owner response. | closed |
| T-08-14 | Information disclosure | Baseline excerpts | high | mitigate | Reference only sanitized evidence metadata. | closed |
| T-08-15 | Repudiation | Owner outcomes | high | mitigate | Persist actual response, date, scope, and rationale per candidate. | closed |
| T-08-16 | Tampering | Phase 09/10 handoff | high | mitigate | Admit only approved bounded scope linked to its brief and decision. | closed |

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---:|---:|---:|---|
| 2026-09-17 | 16 | 16 | 0 | execute-phase L1 audit |

## Sign-Off

- [x] All threats have a disposition.
- [x] No accepted risks require logging.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-09-17
