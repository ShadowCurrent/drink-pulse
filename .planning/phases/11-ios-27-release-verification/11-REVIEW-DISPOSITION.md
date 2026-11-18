# Phase 11: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed in plan 11-12 | 11-REVIEW.md |
| WR-02 | warning | fixed in plan 11-12 | 11-REVIEW.md |
| IN-01 | info | open | 11-REVIEW.md |
| IN-02 | info | fixed in plan 11-12 | 11-REVIEW.md |
| IN-03 | info | limit documented in the class comment; methods not added | 11-REVIEW.md |

All findings are in the gated, test-only `AccessibilityAuditUITests.swift`. Reconciled 2026-11-18 (plan 11-24) with the table above: WR-01, WR-02 and IN-02 were fixed in plan 11-12 (test-only changes), IN-03 has its limit documented in the class comment, and only IN-01 stays open. The earlier footer text ("Phase 11 makes no code fixes, so every finding stays open") predates plan 11-12 and the gap closure. WR-01 and WR-02 affected how far the D11-22 exploratory audit record can be trusted; the audit record was corrected in plan 11-12 (385 reports, 311 byte-wise distinct keys, 9 unreliable rows), and the todo `2026-11-14-fix-accessibility-audit-findings` is completed.

## Review 2 (2026-11-18, gap-closure changes, 68 files since fd292d1)

The first review (2 files) is in git history at fd292d1; 11-REVIEW.md now holds review 2. Finding ids below refer to review 2. Default disposition is open until the owner decides.

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | open | 11-REVIEW.md (review 2) |
| WR-01 | warning | open | 11-REVIEW.md (review 2) |
| WR-02 | warning | open | 11-REVIEW.md (review 2) |
| WR-03 | warning | open | 11-REVIEW.md (review 2) |
| WR-04 | warning | accepted: owner approved the toolbar "Cancel" to system "x" change in plan 11-18 | 11-REVIEW.md (review 2) |
| WR-05 | warning | open | 11-REVIEW.md (review 2) |
| WR-06 | warning | open | 11-REVIEW.md (review 2) |
| WR-07 | warning | open | 11-REVIEW.md (review 2) |
| WR-08 | warning | out of scope for Phase 11 by owner direction (GuidelineAlertCard localisation note) | 11-REVIEW.md (review 2) |
| WR-09 | warning | open | 11-REVIEW.md (review 2) |
| IN-01 | info | open (carried forward from review 1) | 11-REVIEW.md (review 2) |
| IN-02 | info | open | 11-REVIEW.md (review 2) |
| IN-03 | info | open | 11-REVIEW.md (review 2) |
| IN-04 | info | open | 11-REVIEW.md (review 2) |
| IN-05 | info | open | 11-REVIEW.md (review 2) |
| IN-06 | info | open | 11-REVIEW.md (review 2) |
