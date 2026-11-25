# 0047 — Retrospective

**Completed**: 2026-11-25 (executed 2026-11-23 to 2026-11-25, inline, superpowers
`executing-plans`).

## What shipped
- Add Drink step 1: sectioned `List` (Beer & Cider, Wine, Spirits, Mixed & Other), up to three
  Recent drinks that reopen with their serving, search with the system empty state, Cancel role.
  Brandy and Cognac share one row; the Spirits rows have distinct emoji (owner-approved set).
- Step 2 and Edit share `DrinkServingSection`, `DrinkServingOptions` and `PureAlcoholRow`;
  system confirm buttons; the custom sheet-action bar is gone.
- Edit Drink is pushed inside History with Log Again and Delete Drink; type changes through a
  checked list.
- Bug fix: Log Again writes to Apple Health (History rows and Edit, shared `EventActions`).
- Audit classes for Add (steps 1 and 2) and Edit green in standard, dark and AX5.

## What went well
- The plan's pure helpers (groups, Recent, serving options, type selection) went in test-first
  and never needed rework.
- Instrumenting instead of guessing found three non-obvious causes quickly once applied:
  temporary `persistentModelID`, the currency race, and the emoji audit findings.

## What went badly
- Several hypotheses were tried before instrumenting (currency: two; Edit route: two). Each
  wrong guess cost a full UI run. Printing the audit's `detailedDescription` or the hierarchy
  first would have saved most of that.
- Xcode's file index lagged after new or deleted files almost every time; a second build was
  routinely needed.
- UI test scrolling needed three iterations (centre swipe turns wheels; `isHittable` throws on
  lazy rows; frames read mid-scroll).

## Surprises (iOS 27.2)
- A fresh event's `persistentModelID` is temporary and changes on autosave, so it cannot key a
  pushed screen; the `uuid` does.
- `dismiss()` from a pushed link destination inside a value-pushed screen popped to the root.
- NavigationLink labels in the sheet's List failed `contrast` until given explicit primary ink.
- A decorative emoji image as a List label icon produced element-less AX5 audit findings.

## Follow-ups
- Owner: search drawer `.automatic` vs `.always`, no emoji at AX sizes, search-field audit
  exemption (open-questions "Plan 0047 follow-ups").
- Pre-existing: History calendar standard audit `dynamicType`, Today over-limit dark
  `contrast`, Dashboard drink-count flake in long batches.
