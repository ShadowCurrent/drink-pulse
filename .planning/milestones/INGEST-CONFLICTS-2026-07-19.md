## Conflict Detection Report

### BLOCKERS (0)

None. Both blockers from the prior ingest pass are resolved in this re-run:

- The ADR-0005/ADR-0006 LOCKED-vs-LOCKED contradiction is resolved: ADR-0005's
  Status header now reads "Superseded by ADR-0006" (Superseded date 2026-07-18),
  so ADR-0005 classifies as `locked: false`. This is no longer a LOCKED-vs-LOCKED
  conflict — see the auto-resolved INFO entry below.
- The UNKNOWN-classification blocker for `docs/volume-presets-proposal.md` is
  resolved: that entry was removed from `.planning/intel/classifications/` (the
  file does not exist in the repository), so it no longer appears in this ingest
  at all.

### WARNINGS (1)

[WARNING] Stale "Planned" section in docs/product.md vs actual shipped status
  Found: docs/product.md lists six items under "### Planned (Claude Design
  handoff — 2026-05-19, plans in `docs/plans/`)": first-launch onboarding
  (plan-0009), Apple Health write-back (plan-0036), Insights screen (plan-0012),
  History calendar view (plan-0013), Edit entry name/notes/category (plan-0014),
  Log reminders (plan-0016) + fixed Ember accent (plan-0033), Risk language
  rename (plan-0015).
  Impact: docs/roadmap.md and docs/plans/INDEX.md — both DOC-precedence, lower
  than product.md's PRD precedence — mark every one of these plans as ✅ done
  (plan-0036 additionally has an accepted ADR, ADR-0011). Applying default
  precedence (PRD > DOC) naively would make the synthesizer treat these features
  as "not yet built," which contradicts the actual shipped state shown by the
  higher-numbered, more-recent status documents and their linked ADRs. This is
  not extracted as done vs. planned in requirements.md — both facts are recorded,
  see REQ-first-launch-onboarding, REQ-apple-health-writeback, REQ-insights-screen,
  REQ-history-calendar-view, REQ-edit-entry-name-notes-category, REQ-log-reminders,
  REQ-risk-language-rename in .planning/intel/requirements.md.
  → Confirm actual current status before routing to a roadmap. If these are
  indeed shipped, update product.md's "Planned" section as part of the living-docs
  audit (CLAUDE.md's own rule: "Living docs are part of the change").

### INFO (4)

[INFO] Auto-resolved: LOCKED ADR-0006 wins over non-LOCKED ADR-0005 (same scope)
  Note: docs/decisions/0005-density-by-display-unit.md and
  docs/decisions/0006-density-by-mode-and-guideline.md both address the same
  scope (volume→mass density / AlcoholUnit case set). In this re-run, ADR-0005's
  Status header has been formally updated to "Superseded by ADR-0006" (Superseded
  2026-07-18), so it is classified `locked: false`, while ADR-0006 remains
  `locked: true` (Accepted). Per the LOCKED-vs-non-LOCKED rule, ADR-0006 wins
  automatically — no user resolution needed. ADR-0006 is recorded as the sole
  authoritative, locked density rule in .planning/intel/decisions.md; ADR-0005 is
  preserved verbatim as a superseded historical record (same file, same rule as
  ADR-0003 vs ADR-0004). Corroborating (non-authoritative) evidence: docs/domain.md
  and docs/roadmap.md both already described the ADR-0006 two-case model.

[INFO] Cross-ref cycles detected — resolved as benign, non-blocking
  Note: Cycle detection over the `cross_refs` graph (DFS, three-color marking)
  found two cycles: (1) docs/decisions/0003-mvvm-with-repositories.md ↔
  docs/decisions/0004-data-access-query-stateless-vm.md (mutual
  "Superseded by" / "Supersedes" backlink); (2)
  docs/decisions/0005-density-by-display-unit.md ↔
  docs/decisions/0006-density-by-mode-and-guideline.md (mutual "Amends" /
  "Superseded by" backlinks). Both cycles are ordinary bidirectional
  documentation cross-links between an ADR and the ADR that supersedes/amends
  it, not logical/authority ambiguity — each pair is already disambiguated
  independently by explicit Status/locked fields (0003: Status=Superseded,
  locked=false vs 0004: Status=Accepted, locked=true; 0005: Status=Superseded by
  ADR-0006, locked=false vs 0006: Status=Accepted, locked=true — see the
  auto-resolved entry above). Full synthesis proceeded for all four documents
  rather than excluding them, since excluding them would have dropped real,
  unambiguous decision content for no synthesis-safety benefit. Traversal depth
  stayed well under the 50-node cap.

[INFO] docs/plans/INDEX.md header says "Next number: 0037" but the table already
  contains an entry for plan-0037 (status: draft)
  Note: Minor internal inconsistency in a DOC-type file; does not affect any
  decision or requirement content, so it is recorded here for completeness only
  and was not escalated to a WARNING or BLOCKER.

[INFO] No SPEC-type documents were present in this ingest
  Note: `.planning/intel/constraints.md` was created but contains no entries.
  No SPEC-vs-ADR precedence checks were applicable.
