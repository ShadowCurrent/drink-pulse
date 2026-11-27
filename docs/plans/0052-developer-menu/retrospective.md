# 0052 — Retrospective

**Outcome:** Settings has a Debug-only "Developer" section with "Replay Onboarding"; the replay
is a rehearsal (no profile written, onboarding flag untouched) and Today's first-run entrance
plays on dismiss. `UITestSeed` and its fixtures no longer compile into Release.

**What went well:** Rehearsal reused the existing cover and `revealFirstRun()` path, so the
entrance came for free. A Release stub with the same API kept every production call site
unchanged.

**What surprised:** Onboarding Done inserts a new `UserProfile` unconditionally, and every
screen reads `profiles.first` unsorted — a real replay would have created a second profile with
arbitrary precedence. This drove option A and the separate profile-robustness work.

**Follow-ups (open-questions.md, "Store recovery …"):** restore path for `RecoveredStores/`
snapshots, recovery notice, `dp_onboarding_done` left true with no profile (OBS-C), duplicate /
invalid profile handling, update-time re-onboarding.
