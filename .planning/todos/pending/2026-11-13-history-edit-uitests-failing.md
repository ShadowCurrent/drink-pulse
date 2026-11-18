---
created: 2026-11-13T17:00:00.000Z
title: Diagnose failing History edit UI tests (name/notes and category change)
area: testing
severity: major
files:
  - drinkpulseUITests/Features/History/HistoryInteractionUITests.swift
  - drinkpulse/Features/History/EditEventView.swift
audit_acknowledged:
  milestone: v1.4
  at: 2026-11-18
---

## Problem

Two UI tests in `HistoryInteractionUITests` fail deterministically on the iOS 27.2
simulator (iPhone 17), including on the single retry:

- `test_editCustomNameAndNotes_persist()` fails at
  `HistoryInteractionUITests.swift:165`: "After save the row should show the custom
  name 'Tyskie IPA'".
- `test_editCategoryChange_persists()` fails at
  `HistoryInteractionUITests.swift:220`: "After changing to Wine the row should show
  the 150 ml wine default".

Evidence: `build/d1-scoped-ui.log` (git-ignored; DP_RESULT line 2, runs 1 to 3 in the
header comments, failure lines 106, 121, 149, 164). The same two tests fail
identically at the governance commit `ae37187` production state (Dashboard
`GlassEffectContainer` temporarily put back), then again with it restored. So the
failure is not caused by the plan 09-08 Dashboard revert and is unrelated to the
Dashboard. `.planning/debug/resolved/contextmenu-zoom-glitch.md` records
`test_editCategoryChange_persists` as flaky in an earlier session; it now fails
deterministically. It is not known whether the app behavior regressed (a real
data-integrity defect in the edit flow) or the tests are stale.

## Waiver

Owner decision 2026-11-13 (Polish: "Osobny defekt, waiver (Rekomendowane)"): these two
tests are recorded as a separate pre-existing defect and are waived by name for the
plan 09-08 scoped UI gate only. The waiver does not extend to any later plan or to the
phase verification; they must be diagnosed and fixed (or the tests corrected with
evidence) before a full-suite gate at milestone close.

## Solution

Diagnose separately, for example with `/gsd-debug`. Start by running the two tests in
isolation on HEAD and on an earlier commit to find when they started failing
(`git bisect` over the History and Edit files), then decide whether the app or the
test is wrong. If the app is wrong, add a failing regression test first, per the
project testing rules. Consult Apple documentation and Xcode MCP first.
