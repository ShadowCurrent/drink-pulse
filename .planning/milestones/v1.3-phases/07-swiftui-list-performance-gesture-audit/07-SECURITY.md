---
phase: 07
slug: swiftui-list-performance-gesture-audit
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-04
---

# Phase 07 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| user gesture → SwiftData store | Long-press + tap can irreversibly destroy a `ConsumptionEvent` and its HealthKit sample. | Health data (delete) |
| VoiceOver Actions rotor → SwiftData store | A second reachable path to Delete (accessibility action) must be as safe as the touch path. | Health data (delete) |
| launch arguments → app state | UI-test seeding hooks cross from the test process into app startup. | Synthetic test data only |
| view-layer identity → CloudKit LWW de-dup | `ConsumptionEvent.uuid` underpins `RecordDeduplicator` and last-write-wins conflict resolution. | Sync identity, no new field |
| `UserProfile` (`@Observable`) → row views | Body weight, DOB, and goal are personal health data; row views must not over-observe. | Personal health data (narrowed, not widened) |
| user selection → `UserProfile.guidelineChoice` | Chosen guideline determines every threshold consumption is compared against. | Guideline preference |
| onboarding list vs. Settings list | Two independently maintained lists of the same choices can diverge. | Guideline preference (consistency) |
| `List` chrome → hand-rolled card chrome | Leaving `List` gives up default row insets, scrolling, and hit targets. | UI usability, not data |
| cached view state → rendered dates | Precomputed section titles are time-dependent; a stale cache misreports which day a drink belongs to. | Health data (display accuracy) |
| `@Query` fetch bounds → memory/CPU | Query bounds determine how much of the user's history is materialized at once. | Health data volume |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-07-01 (07-01) | Denial of Service | `EventContextMenu` destructive button | high | mitigate | Delete routes through `isPresentingDeleteConfirmation` + confirmation dialog; pinned by `test_contextMenuDelete_cancel_keepsRow`. | closed |
| T-07-02 (07-01) | Tampering | `ConsumptionEvent` identity vs. CloudKit LWW | medium | mitigate | Reused existing `uuid`; no schema file changed (verified). | closed |
| T-07-03 (07-01) | Denial of Service | SwiftData `VersionedSchema` recovery | high | mitigate | No `@Model` shape touched; asserted by `git diff --name-only` criterion. | closed |
| T-07-04 (07-01) | Information Disclosure | new accessibility label strings | low | accept | Static English copy, no user data, no new logger interpolation. | closed |
| T-07-05 (07-01) | Tampering | UI-test hooks reaching production | low | mitigate | Reuses existing `-dp_uitest`-gated fixture; no new hook added. | closed |
| T-07-06 (07-02) | Information Disclosure | `EventRowStrings` | medium | mitigate | Render-only: no logger, no print, no `Codable`, no export path, no storage (verified). | closed |
| T-07-07 (07-02) | Information Disclosure | `RowUnitContext` | low | mitigate | Carries only 3 display-unit enums, no body metrics — strictly narrows reachable data. | closed |
| T-07-08 (07-02) | Denial of Service | SwiftData `VersionedSchema` recovery | high | mitigate | No `@Model` type / schema file touched (verified). | closed |
| T-07-09 (07-02) | Tampering | `daySections` regrouping | medium | mitigate | Grouping/ordering/empty-case pinned by 5 tests. | closed |
| T-07-10 (07-03) | Denial of Service | new `accessibilityActions` Delete | high | mitigate | Routes through same `isPresentingDeleteConfirmation` flag as touch path; `ContextMenuDeleteConfirmationUITests` (3/3) passes. | closed |
| T-07-11 (07-03) | Information Disclosure | row observation scope | low | mitigate | `RowUnitContext` replaces `UserProfile?`; zero-`UserProfile` greps hold in all 3 row files. | closed |
| T-07-12 (07-03) | Tampering | UI-test hooks reaching production | low | mitigate | System-provided `-UIPreferredContentSizeCategoryName` arg alters no app state; no new seeding hook. | closed |
| T-07-13 (07-03) | Denial of Service | SwiftData `VersionedSchema` recovery | high | mitigate | No `@Model` type / schema file touched (verified). | closed |
| T-07-14 (07-03) | Information Disclosure | new accessibility label content | low | accept | `history.row.hasNote` announces existence only, never note content. | closed |
| T-07-15 (07-04) | Tampering | divergent guideline lists across two screens | medium | mitigate | `GuidelineChoice.selectable` is single source; zero hard-coded lists remain (verified by grep). | closed |
| T-07-16 (07-04) | Repudiation | selected state conveyed by glyph alone | medium | mitigate | `.accessibilityAddTraits(.isSelected)` added; pinned by 2 UI tests. | closed |
| T-07-17 (07-04) | Tampering | accidental copy change while deleting duplicate name mapping | low | mitigate | Both name sources read in full before deletion; `Localizable.xcstrings` diff empty. | closed |
| T-07-18 (07-04) | Information Disclosure | new accessibility identifiers | low | accept | Identifiers derive from public enum raw values, carry no user data. | closed |
| T-07-19 (07-04) | Denial of Service | SwiftData `VersionedSchema` recovery | high | mitigate | `GuidelineChoice` is a plain `Codable` enum, not a model; no schema file touched (verified). | closed |
| T-07-20 (07-04) | Denial of Service | `List` → `ScrollView` conversion | medium | mitigate | Row insets re-supplied inside content shape; all 6 rows hittable and ≥44pt; `OnboardingFlowUITests` still passes. | closed |
| T-07-21 (07-04) | Tampering | `SettingsSection` shared component (12 call sites) | low | mitigate | Purely additive second initializer; diff over `Features/Settings/` shows no other call site touched. | closed |
| T-07-20 (07-05) | Tampering | UI-test seeding hooks reaching production | medium | mitigate | Follows established pattern: resolved once from `ProcessInfo`, gated by `UITestSeed.isActive`, synthetic data only; single call site verified by grep. | closed |
| T-07-21 (07-05) | Repudiation | precomputed `Today`/`Yesterday` titles going stale | medium | mitigate | 3 refresh triggers (data change, scene activation, calendar day change) through one recompute method; pinned by injected-clock unit tests. | closed |
| T-07-22 (07-05) | Denial of Service | loading row displacing pagination sentinel | high | mitigate | Separate `if` (not `else if`); UI test A/B-proven to fail when sentinel displaced; grep guard on `LoadMoreSentinel(`. | closed |
| T-07-23 (07-05) | Information Disclosure | new loading-state copy | low | accept | `history.list.loadingOlder` is static English copy, no user data, no logger call added. | closed |
| T-07-24 (07-05) | Denial of Service | SwiftData `VersionedSchema` recovery | high | mitigate | `FetchDescriptor` adjusted, not the model; no schema file touched (verified). | closed |

*Status: open · closed · open — below {block_on} threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

**Note:** Threat IDs T-07-20 and T-07-21 were independently assigned by plans 07-04 and 07-05 to unrelated components (ID collision across sibling plans, not a shared threat). Distinguished above by originating plan.

Supply chain (all 5 plans): **not applicable** — no npm/pip/cargo/SPM package installed, no external dependency added in this phase.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-07-01 | T-07-04 | New accessibility label strings are static English copy, no user data, no new logger interpolation. | plan-0007 executor | 2026-08-04 |
| AR-07-02 | T-07-14 | `history.row.hasNote` announces note existence only, never spoken/logged/exported content. | plan-0007 executor | 2026-08-04 |
| AR-07-03 | T-07-18 | New accessibility identifiers derive from public enum raw values, expose nothing a screenshot wouldn't. | plan-0007 executor | 2026-08-04 |
| AR-07-04 | T-07-23 | New loading-state copy is static English, no user data. | plan-0007 executor | 2026-08-04 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-04 | 26 | 26 | 0 | /gsd-secure-phase (register built from 5 PLAN.md threat_model blocks, verified against 5 SUMMARY.md Threat Flags / Threat Model Compliance sections; ASVS L1 — grep-depth sufficient, no auditor sub-agent needed since threats_open: 0 and register was authored at plan time) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-04
