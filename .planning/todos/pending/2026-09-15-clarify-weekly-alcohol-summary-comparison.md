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
