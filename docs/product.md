# Product

## Vision

A calm, private alcohol tracker for people who want honest insight into
their drinking habits — without accounts, subscriptions, or cloud sign-ins.
The app shows what you drank, when, and how it compares to health guidelines,
then gets out of the way.

## Privacy stance

- No account required. Ever.
- Data lives on-device; iCloud sync is opt-in via the user's own Apple ID.
- No analytics, no crash reporters, no third-party SDKs.
- No AI features that send data off-device.

## Target platforms

- **Phase 1**: iPhone (primary)
- **Phase 2**: iPad, Apple Watch complication
- **Minimum deployment**: iOS 17

## Core user stories

### Logging
- As a user I can quickly log a drink by choosing its type, volume, and strength.
- As a user I can log multiple servings at once (count multiplier).
- As a user I can back-date an entry to yesterday or earlier.
- As a user I can add an optional price to track spending.

### Insight
- As a user I can see today's total alcohol intake vs my weekly guideline.
- As a user I can browse my history grouped by day.
- As a user I can see my alcohol units and pure-alcohol grams per entry.

### Settings
- As a user I can set my biological sex and age.
- As a user I can choose a health guideline (WHO / DE / UK / US / custom).
- As a user I can set my preferred volume unit (ml / US fl oz / Imperial fl oz).
- As a user I can set my preferred alcohol display unit (grams / UK units / standard drinks).
- As a user I can configure ABV picker precision (0.1 % or 0.5 %).

Note: `bodyWeightKg` and `currency` fields exist in the `UserProfile` model but are not yet
surfaced in Settings UI — they are scaffolded for future BAC and spending-tracker features.

### Future
- BAC estimate (Widmark, labeled as estimate / not medical advice). Requires body weight input in Settings.
- Currency preference and spending tracker.
- Custom drink templates.
- Monthly trend charts.
- Widget / Live Activity showing today's units.
- Apple Watch quick-log complication.
- Notifications for weekly summary.
