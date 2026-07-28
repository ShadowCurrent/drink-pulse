---
created: 2026-07-26T17:02:13.316Z
title: Rename app display name to DrinkPulse
area: general
severity: cosmetic
cluster: none
files:
  - drinkpulse.xcodeproj/project.pbxproj (TARGET_NAME/PRODUCT_NAME are lowercase "drinkpulse")
---

## Problem

User wants the app to display as "DrinkPulse" (proper case) everywhere, not
the lowercase "drinkpulse" target/product name. `PRODUCT_NAME = "$(TARGET_NAME)"`
resolves to lowercase `drinkpulse` (the Xcode target name), which is likely
what shows as the home-screen app name since no explicit
`INFOPLIST_KEY_CFBundleDisplayName` override was found in the generated
Info.plist build settings. Docs (README.md, .planning/PROJECT.md) already
say "DrinkPulse" correctly — the gap is the shipped app's actual display
name plus any other lowercase "drinkpulse" references in project config.

## Solution

TBD — options to weigh:
- Add `INFOPLIST_KEY_CFBundleDisplayName = DrinkPulse` to build settings
  (non-invasive, doesn't touch bundle id / target/folder name).
- Full target rename (Xcode target "drinkpulse" → "DrinkPulse") — touches
  `project.pbxproj`, scheme files, possibly folder name; higher risk, would
  need care around `PRODUCT_BUNDLE_IDENTIFIER` (`com.haniewicz.drinkpulse`,
  `com.drinkpulse.drinkpulseTests`) staying unchanged so it's not a new app
  from the App Store's/TestFlight's perspective.
- Sweep for other stray lowercase "drinkpulse" references intended to be
  the display name (e.g. any hardcoded strings in Settings/About screen).

Needs a scope decision before implementing (likely a quick task, not a full plan).
