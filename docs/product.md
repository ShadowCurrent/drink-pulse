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
- **Minimum deployment**: iOS 26

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
- As a user I can set my preferred alcohol display unit (grams / standard drinks; the UK reads "units").
- As a user I can configure ABV picker precision (0.1 % or 0.5 %).

Note: `bodyWeightKg` and `currency` fields exist in the `UserProfile` model but are not yet
surfaced in Settings UI — they are scaffolded for future BAC and spending-tracker features.

### Planned (Claude Design handoff — 2026-05-19, plans in `docs/plans/`)

- **First-launch onboarding** — 3 steps (welcome / optional profile / guideline);
  each step skippable, persisted via `@AppStorage` ([plan-0009](plans/0009-onboarding-flow/)).
- **Insights screen** — area chart, weekday patterns, health metrics,
  multi-guideline comparison; scope selector with Week / Month / Year /
  All Time ([plan-0012](plans/0012-insights-screen/)).
- **History calendar view** — clickable days with inline detail panel,
  month navigation, daily-limit colour coding
  ([plan-0013](plans/0013-history-calendar-clickable-days/)).
- **Edit entry: custom name + notes** — override drink name (e.g. "Some
  Super IPA"), add free-form notes, change category in place
  ([plan-0014](plans/0014-edit-entry-notes-and-category/)).
- **Log reminders** — opt-in daily nudge to log
  ([plan-0016](plans/0016-log-reminder-notifications/)). The app ships a single
  fixed Ember accent (the multi-theme palettes from plan-0008 were removed in
  [plan-0033](plans/0033-remove-color-themes-fixed-accent/)); Light / Dark /
  System mode is retained.
- **Risk language** — "Low Risk / Moderate Risk / High Risk" replaces
  "Safe / Caution / Exceeded" everywhere
  ([plan-0015](plans/0015-risk-language-rename/)).

### Future

- BAC estimate (Widmark, labeled as estimate / not medical advice). Requires body weight input in Settings.
- Currency preference and spending tracker (dedicated screen — spend
  already shown inside the Insights card per design).
- Custom drink templates.
- Monthly trend charts beyond what Insights provides.
- Widget / Live Activity showing today's units.
- Apple Watch quick-log glance (today summary + log drink, iOS app
  extension — not standalone watchOS).
- Notifications for weekly summary.
- **AI natural-language drink entry** — type "had a Tyskie at 9pm" and
  have the app parse it. On-device model preferred to preserve privacy.
- **PDF export of Insights** — formatted monthly summary for personal
  archive or sharing with a clinician.
