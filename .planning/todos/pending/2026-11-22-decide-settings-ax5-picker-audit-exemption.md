---
created: 2026-11-22T10:06:11.763Z
title: Decide Settings AX5 picker audit exemption
area: testing
severity: minor
files:
  - drinkpulseUITests/Features/Settings/SettingsDynamicTypeUITests.swift
---

## Problem

`SettingsDynamicTypeUITests` exempts `dynamicType` / `textClipped` on the five Preferences
picker labels and `none#type=nil` at AX5 (system `.navigationLink` style, D0043-4). Render shows
nothing clipped; same shape as D11-28. Owner deferred it to the device check (2026-11-21).

## Solution

Owner accepts (decision id) or picks another AX layout after the AX5 device check; then remove
the open-questions entry.
