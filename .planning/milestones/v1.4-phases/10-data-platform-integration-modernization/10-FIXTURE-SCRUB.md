# Phase 10 Fixture Scrub Guide (Owner)

This guide is for the owner only. It describes how to turn your real pre-upgrade DrinkPulse export into a placeholder-only test fixture (`sanitized-export-v2.json`) that is safe to commit.

## Why (D-07)

The sanitized export is the real-shape evidence for backup compatibility (Phase 08 C009, decisions D-07 to D-09). It must contain no personal data.

This is a one-way door. Git history is permanent: a value that slips into a commit cannot be cleanly retracted. For that reason:

- Scrubbing is mechanical (a script, below), not manual editing.
- You review the whole output by eye before anything is committed.
- A lint test (`SanitizedBackupFixtureTests`) re-checks every rule in "Allowed values" on every test run, and stays in the suite.

## Workflow

1. On the iPhone, still on the currently installed build (do not install the Phase 10 build yet), open Settings, Export, and save the JSON.
2. Move that file to a folder outside this repository (for example `~/Documents/dp-scrub/`). Never upload it anywhere.
3. Save the script below as `scrub.py` in that same outside folder.
4. Run it with both the input path and the output path outside this repository:

   ```bash
   python3 ~/Documents/dp-scrub/scrub.py ~/Documents/dp-scrub/original.json ~/Documents/dp-scrub/scrubbed.json
   ```

   Do not name any file with the ignored backup naming (`drinkpulse-backup-*.json`). That pattern is git-ignored on purpose.
5. Read the entire output yourself and tick the review checklist at the end of this guide.
6. Only then copy `scrubbed.json` to `drinkpulseTests/Domain/DataTransfer/Fixtures/sanitized-export-v2.json` in this repository.
7. Keep your original export locally. Plan 10-12's import round trip reuses it.

Never run the script with an input or output path inside this repository. The script refuses paths inside any directory that contains a `.git` entry.

## Allowed values

This section is authoritative. The lint test mirrors every item below exactly; the script implements every item below exactly. Keep all three in sync.

Top level and counts:

- `version` stays 2. Only keys `version`, `exportedAt`, `events`, `templates`, `profile` are allowed at top level.
- `exportedAt` is fixed to `2026-01-15T12:00:00Z`.
- At most 14 events, chosen to keep one example of every present shape: each category, each `enteredUnit` value, each optional-key presence pattern, uuid present or absent. The output is sorted by original timestamp ascending.
- At most 6 templates.
- The key `healthKitUUID` never appears.

Event uuids:

- A non-null event uuid is replaced by `00000000-0000-4000-8000-` followed by the 12-digit zero-padded decimal of `r + 1`, where `r` is the event's zero-based position in the output. Example: position 0 becomes `00000000-0000-4000-8000-000000000001`.
- A null or absent uuid stays absent.

Template uuids:

- A non-null template uuid is replaced by `00000000-0000-4000-9000-` followed by the 12-digit zero-padded decimal of the template's one-based position in the output. Example: first template becomes `00000000-0000-4000-9000-000000000001`.
- Every template in the fixture carries a uuid (templates without one are always inserted new by the importer).

Event timestamps:

- Every event `timestamp`, `creationDate` and `modifiedDate` is re-derived as the fixed base `2026-01-05T09:00:00Z` plus `r` days plus `m` whole minutes, where `r` is the event's zero-based output position and `m` is an integer from 0 through 119. Seconds are always zero.
- Which optional date keys were present is preserved, and so is whether `modifiedDate` was later than `creationDate`.

Template and profile dates:

- Template `modifiedDate`, where non-null, is exactly `2026-01-05T09:00:00Z` (key presence preserved).
- Profile `modifiedDate`, where non-null, is exactly `2026-01-05T09:00:00Z` (key presence preserved).

Free text and money:

- `customName`, where non-null, becomes `name-N`; `notes`, where non-null, becomes `note-N` (N is the 1-based event position).
- Template `name` becomes `template-N` (N is the 1-based template position).
- `price`, where non-null, is mapped to the nearest of `1.0`, `2.5`, `5.0`, `10.0`.
- `priceCurrency` is `"USD"` wherever non-null.

Kept as-is: event `volumeMl`, `abv`, `quantity`, `category`, `icon`, `enteredUnit`; template `category`, `defaultVolumeMl`, `abv`, `icon`, `colorHex`, `isFavorite`, `isArchived`; profile `unitSystem`, `abvPrecisionPermille`, `alcoholUnit`.

Profile:

- `bodyWeightKg` is `80.0`.
- `biologicalSex` is `"male"`.
- `dateOfBirth` is `"1990-01-01T00:00:00Z"` only if the original had one; otherwise absent.
- `guidelineChoice` is `"who"`.
- `weeklyGoalGrams` is `100.0`.
- `currency` is `"USD"`.
- `modifiedDate` as stated above.

Any unknown key makes the script abort instead of copying it.

## Scrub script

```python
#!/usr/bin/env python3
"""Scrub a DrinkPulse export into a placeholder-only test fixture.

Usage: scrub.py INPUT.json OUTPUT.json   (both paths OUTSIDE the repository)
Implements the "Allowed values" section of 10-FIXTURE-SCRUB.md exactly.
"""
import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

BASE = datetime(2026, 1, 5, 9, 0, 0, tzinfo=timezone.utc)
EXPORTED_AT = "2026-01-15T12:00:00Z"
FIXED_MODIFIED = "2026-01-05T09:00:00Z"
EVENT_UUID_PREFIX = "00000000-0000-4000-8000-"
TEMPLATE_UUID_PREFIX = "00000000-0000-4000-9000-"
MAX_EVENTS = 14
MAX_TEMPLATES = 6
PRICE_CHOICES = (1.0, 2.5, 5.0, 10.0)

TOP_KEYS = {"version", "exportedAt", "events", "templates", "profile"}
EVENT_KEYS = {
    "uuid", "timestamp", "creationDate", "volumeMl", "abv", "quantity",
    "enteredUnit", "category", "icon", "customName", "notes", "price",
    "priceCurrency", "modifiedDate",
}
TEMPLATE_KEYS = {
    "uuid", "name", "category", "defaultVolumeMl", "abv", "icon", "colorHex",
    "isFavorite", "isArchived", "modifiedDate",
}
PROFILE_KEYS = {
    "bodyWeightKg", "biologicalSex", "dateOfBirth", "guidelineChoice",
    "weeklyGoalGrams", "unitSystem", "currency", "abvPrecisionPermille",
    "alcoholUnit", "modifiedDate",
}


def die(message):
    sys.exit("ABORT: " + message)


def inside_repository(path):
    for parent in [path.resolve()] + list(path.resolve().parents):
        if (parent / ".git").exists():
            return True
    return False


def check_keys(obj, allowed, label):
    unknown = set(obj) - allowed
    if unknown:
        die("unknown key(s) in %s: %s" % (label, sorted(unknown)))


def parse_date(text):
    return datetime.fromisoformat(text.replace("Z", "+00:00"))


def fmt(dt):
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def nearest_price(value):
    return min(PRICE_CHOICES, key=lambda c: abs(c - value))


def event_shape(e):
    optional = tuple(sorted(k for k in (
        "uuid", "creationDate", "enteredUnit", "customName", "notes",
        "price", "priceCurrency", "modifiedDate") if e.get(k) is not None))
    return (e["category"], e.get("enteredUnit"), optional)


def pick_events(events):
    # Sorted by original timestamp ascending; keep one example of each shape first.
    events = sorted(events, key=lambda e: parse_date(e["timestamp"]))
    chosen, seen = [], set()
    for e in events:
        shape = event_shape(e)
        if shape not in seen and len(chosen) < MAX_EVENTS:
            seen.add(shape)
            chosen.append(e)
    return chosen  # already ascending because we iterated in order


def scrub_event(e, r):
    check_keys(e, EVENT_KEYS, "event")
    minutes = (r * 7) % 120  # deterministic, 0..119 whole minutes
    day = BASE + timedelta(days=r)
    out = {
        "timestamp": fmt(day + timedelta(minutes=minutes)),
        "volumeMl": e["volumeMl"],
        "abv": e["abv"],
        "category": e["category"],
        "icon": e["icon"],
    }
    if e.get("quantity") is not None:
        out["quantity"] = e["quantity"]
    if e.get("enteredUnit") is not None:
        out["enteredUnit"] = e["enteredUnit"]
    if e.get("uuid") is not None:
        out["uuid"] = EVENT_UUID_PREFIX + "%012d" % (r + 1)
    if e.get("customName") is not None:
        out["customName"] = "name-%d" % (r + 1)
    if e.get("notes") is not None:
        out["notes"] = "note-%d" % (r + 1)
    if e.get("price") is not None:
        out["price"] = nearest_price(e["price"])
    if e.get("priceCurrency") is not None:
        out["priceCurrency"] = "USD"
    created = e.get("creationDate")
    modified = e.get("modifiedDate")
    if created is not None:
        out["creationDate"] = fmt(day + timedelta(minutes=max(minutes - 1, 0)))
    if modified is not None:
        later = created is not None and parse_date(modified) > parse_date(created)
        if later:
            out["modifiedDate"] = fmt(day + timedelta(minutes=min(minutes + 1, 119)))
        elif created is not None:
            out["modifiedDate"] = out["creationDate"]
        else:
            out["modifiedDate"] = fmt(day + timedelta(minutes=minutes))
    return out


def scrub_template(t, position):
    check_keys(t, TEMPLATE_KEYS, "template")
    out = {
        "uuid": TEMPLATE_UUID_PREFIX + "%012d" % position,
        "name": "template-%d" % position,
        "category": t["category"],
        "defaultVolumeMl": t["defaultVolumeMl"],
        "abv": t["abv"],
        "icon": t["icon"],
        "colorHex": t["colorHex"],
        "isFavorite": t.get("isFavorite", False),
        "isArchived": t.get("isArchived", False),
    }
    if t.get("modifiedDate") is not None:
        out["modifiedDate"] = FIXED_MODIFIED
    return out


def scrub_profile(p):
    check_keys(p, PROFILE_KEYS, "profile")
    out = {
        "bodyWeightKg": 80.0,
        "biologicalSex": "male",
        "guidelineChoice": "who",
        "weeklyGoalGrams": 100.0,
        "unitSystem": p["unitSystem"],
        "currency": "USD",
        "abvPrecisionPermille": p["abvPrecisionPermille"],
        "alcoholUnit": p["alcoholUnit"],
    }
    if p.get("dateOfBirth") is not None:
        out["dateOfBirth"] = "1990-01-01T00:00:00Z"
    if p.get("modifiedDate") is not None:
        out["modifiedDate"] = FIXED_MODIFIED
    return out


def main():
    if len(sys.argv) != 3:
        die("usage: scrub.py INPUT.json OUTPUT.json")
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    if inside_repository(src) or inside_repository(dst):
        die("input and output must be outside any git repository")
    if dst.name.startswith("drinkpulse-backup-"):
        die("do not use the ignored backup file naming")
    data = json.loads(src.read_text())
    check_keys(data, TOP_KEYS, "top level")
    if data.get("version") != 2:
        die("export version must be 2")
    events = [scrub_event(e, r) for r, e in enumerate(pick_events(data["events"]))]
    out = {"version": 2, "exportedAt": EXPORTED_AT, "events": events}
    templates = data.get("templates") or []
    if templates:
        out["templates"] = [scrub_template(t, i + 1) for i, t in enumerate(templates[:MAX_TEMPLATES])]
    if data.get("profile") is not None:
        out["profile"] = scrub_profile(data["profile"])
    if "healthKitUUID" in json.dumps(out):
        die("healthKitUUID must never appear")
    dst.write_text(json.dumps(out, indent=2, sort_keys=True) + "\n")
    print("wrote %d events, %d templates" % (len(events), len(out.get("templates", []))))


if __name__ == "__main__":
    main()
```

Note on the script and uuid-less events: events without a uuid keep no uuid and are de-duplicated on import by date, volume, abv and quantity, so make sure the output keeps at least one such event if your original had one (the shape selection does this automatically).

## Review checklist

Tick every box before replying "approved" to the Task 2 checkpoint.

- [ ] I ran the script with the input and output paths both outside this repository.
- [ ] I read the whole scrubbed output, top to bottom, by eye.
- [ ] No notes, custom names or other free text from my real data remain (only `name-N`, `note-N`, `template-N`).
- [ ] No real prices remain (only 1.0, 2.5, 5.0, 10.0) and every currency is `USD`.
- [ ] No real body metrics remain (weight 80.0, goal 100.0, sex `male`, DOB only `1990-01-01T00:00:00Z` or absent).
- [ ] No real timestamps remain: every date is in January 2026, and the base is `2026-01-05T09:00:00Z` plus whole days and under 120 minutes.
- [ ] Every uuid is a synthetic `00000000-0000-4000-8000-...` (events) or `00000000-0000-4000-9000-...` (templates) value.
- [ ] The file contains no key named `healthKitUUID`.
- [ ] The file name is `sanitized-export-v2.json` and not `drinkpulse-backup-*.json`.
- [ ] My original export stays outside the repository.
