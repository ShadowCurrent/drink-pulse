---
phase: 10
review: 10-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "New \"no main file or WAL stays at the live path\" claim is false when the failed move is the WAL"
  - id: IN-01
    severity: info
    disposition: fixed
    title: "Compensating-move failure branch is untested"
  - id: IN-02
    severity: info
    disposition: fixed
    title: "`recoverStore` rollback nests six levels deep and mixes two responsibilities"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "New error branches ship without tests, against the AGENTS.md \"error paths\" rule"
  - id: IN-03
    severity: info
    disposition: fixed
    title: "Recovery failure masks the original open error"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Fetch failures are swallowed with `try?` and turn into wrong notification content or a silent cancel"
  - id: WR-04
    severity: warning
    disposition: deferred
    title: "Store recovery runs for any open error and can collide or partially move files"
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "`corruptedStore_reportsRecoveryAndOpensFresh` writes to the real Application Support and can race other suites"
open: 0
total: 8
recorded: 2026-11-10T17:47:00.977Z
---

# Phase 10: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 10-REVIEW-FIX.md |
| IN-01 | info | fixed | 10-REVIEW-FIX.md |
| IN-02 | info | fixed | 10-REVIEW-FIX.md |
| WR-02 | warning | fixed | 10-REVIEW-FIX.md (not in the current review) |
| IN-03 | info | fixed | 10-REVIEW-FIX.md (not in the current review) |
| WR-03 | warning | fixed | 10-REVIEW-FIX.md (not in the current review) |
| WR-04 | warning | deferred | Collision and partial-move parts fixed; the "any open error" trigger stays open as a product decision, see open-questions.md entry "Store recovery fires on any ModelContainer open error" (not in the current review) |
| WR-05 | warning | fixed | 10-REVIEW-FIX.md (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
