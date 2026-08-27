---
created: 2026-08-27T20:51:26.704Z
title: Scope name autocomplete by drink category and ABV
area: general
severity: minor
files:
  - drinkpulse/Features/History/Components/CustomNameSuggestionSection.swift
  - drinkpulse/Features/AddDrink/DrinkDetailInputView.swift
  - drinkpulse/Features/History/EditEventView.swift
  - drinkpulse/Domain/CustomNameSuggestionFilter.swift
---

## Problem

Custom-name autocomplete currently builds a flat list from every historical
`ConsumptionEvent` with a name. This can suggest a beer name while adding wine,
or otherwise mix names between unrelated drink categories. A suggestion is also
only a string, so choosing a previously logged product does not restore its
known ABV and the user must select the strength again.

Suggestions should always be scoped to the category currently selected in the
add/edit flow. Selecting a suggestion should fill both its name and the ABV
recorded for that same category/name combination.

## Solution

Pass the active `DrinkCategory` and an ABV binding/callback into
`CustomNameSuggestionSection`. Build suggestions from lightweight historical
records containing normalized name, category, ABV, and recency instead of
discarding everything except the name. Filter by exact category before applying
the existing text matching, deduplication, ordering, and result limit.

When the same normalized name exists more than once in the selected category,
use a simple deterministic rule, preferably the most recently logged matching
event, to choose its ABV. On selection, update the name and ABV together while
keeping the strength picker valid for the user's configured precision. Apply
the same behavior to both add and edit screens and cover category isolation,
duplicate-name resolution, and ABV autofill with focused tests.

Do not add fuzzy cross-category matching, learned ranking, a separate product
database, or automatic volume/price/notes filling in this iteration.
