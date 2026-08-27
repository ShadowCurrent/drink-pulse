---
created: 2026-08-27T20:45:21.957Z
title: Add practical History list filtering
area: general
severity: minor
files:
  - drinkpulse/Features/History/HistoryView.swift
  - drinkpulse/Features/History/HistoryListQueryView.swift
---

## Problem

The History list can only be browsed chronologically. As the number of logged
drinks grows, finding a specific entry by its drink/custom name or narrowing the
list to a useful date period requires manual scrolling and repeated pagination.

Add focused filtering to the list segment only. The useful initial scope should
cover text search by the name displayed for an event and a simple date filter.
The result must preserve the existing day grouping, stable row identity,
edit/delete interactions, accessibility, and incremental loading behavior.

## Solution

Prefer native SwiftUI controls: `.searchable` for case- and
diacritic-insensitive name matching, plus one compact date-filter control with a
small set of useful choices such as All, Today, Last 7 Days, and Last 30 Days.
Show a clear empty-filter result and make active filters easy to reset.

Keep filtering state in `HistoryView` and pass the minimum required values into
the list query/view-model boundary. Decide during planning whether the date
constraint belongs in the SwiftData predicate or in the existing row-building
pipeline so pagination remains correct. Do not introduce saved searches,
compound rule builders, arbitrary metadata filters, custom query syntax, or a
new filtering framework in the initial version.
