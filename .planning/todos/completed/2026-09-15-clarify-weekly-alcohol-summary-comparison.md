---
created: 2026-09-15T10:31:39.791Z
title: Clarify weekly alcohol summary comparison
area: general
severity: minor
files:
  - drinkpulse/Services/WeeklySummaryService.swift:107
  - drinkpulse/Localizable.xcstrings
  - drinkpulse/Domain/WeeklySummaryCalculator.swift
---

## Problem

The user requests clearer wording in the weekly alcohol consumption notification when consumption decreased. The message should explicitly say that consumption in the last completed week was lower than in the week immediately before it. Both compared periods must be clear from the notification itself.

Original request (Polish): „zaktualizuj tygodniowe powiadomienie o spożyciu alkoholu tak aby było jasne, że spożycie w ubiegłym tygodniu było niższe niż jeszcze poprzedniego tygodnia”.

## Solution

Update the localized weekly summary decrease message (`weeklySummary.notification.body.down`) to explicitly identify the last completed week and the preceding week. Suggested Polish wording: „W ubiegłym tygodniu spożycie alkoholu było o %d%% niższe niż w tygodniu poprzedzającym”. Preserve the existing percentage placeholder and apply equivalent clarity to supported translations. Verify that the wording matches the periods used by WeeklySummaryCalculator and fits the notification presentation.

## Closing note

Closed 2026-11-09 by plan 10-10 (phase 10, INT-01, D-16). The wording was applied per `10-DECISION-F4.md`; the option chosen by the owner was as-of-last-visit. All five `weeklySummary.notification.body.*` English values in `drinkpulse/Localizable.xcstrings` now carry the five owner-approved strings verbatim, with the existing placeholders unchanged (one `%d%%` in `down` and `up`, none in the other three). `WeeklySummaryCalculator` and the plus or minus 5 percent band are unchanged.

The Polish wording suggested above did not apply, because the app is English only.

### UI test exemption (AGENTS.md UI tests rule, owner-accepted 2026-11-08)

The five changed bodies have no `drinkpulseUITests` test because XCUITest cannot read system notification bodies: the bodies exist only inside scheduled system notifications. Substitute evidence: the `WeeklySummaryCopyTests` literal-string assertions on the exact `UNNotificationRequest` body that `WeeklySummaryService` hands to the notification center, plus the plan 10-12 device session, which records natural weekly delivery if it is observed (best effort, not guaranteed within the session). The wording authority is `10-DECISION-F4.md`.
