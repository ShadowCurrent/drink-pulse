import Foundation
import SwiftData

@Model
final class ConsumptionEvent {
    /// Stable record identity (plan-0023). NOT `@Attribute(.unique)` — CloudKit
    /// cannot enforce uniqueness, so de-dup/upsert by `uuid` lives in app code
    /// (`RecordDeduplicator`, importer). New objects auto-get one; a creation-time
    /// collision check regenerates on the (astronomically unlikely) clash.
    var uuid: UUID = UUID()

    /// When the drink was **consumed** (the user may backdate it). Renamed from the
    /// old `timestamp`; `@Attribute(originalName:)` maps the existing V1 column so no
    /// data is lost. Constant inline default (CloudKit needs one); `init` sets `.now`.
    @Attribute(originalName: "timestamp")
    var consumptionDate: Date = Date(timeIntervalSince1970: 0)

    /// When this record was **created** (logged), as opposed to when the drink was
    /// consumed. Non-optional. New inserts seed it from `consumptionDate`; the V1→V2
    /// migration backfills existing rows with their `consumptionDate` (no earlier
    /// creation instant is known). Constant inline default for CloudKit.
    var creationDate: Date = Date(timeIntervalSince1970: 0)
    /// Volume of a **single** portion in millilitres. The number of portions logged
    /// in one entry lives in `quantity` — never fold the count into this value.
    var volumeMl: Double = 0
    /// Plain fraction, e.g. 0.05 for 5% ABV.
    var abv: Double = 0
    /// Number of identical single portions in this one log (e.g. "Bottle ×10").
    var quantity: Int = 1

    /// The unit system in effect when this event was logged (provenance, "C′" /
    /// ADR-0007). Drives which serving *name* is shown — stable across later
    /// unit-mode switches. `volumeMl` stays the canonical truth; this never
    /// affects any calculation. It is permanent provenance: never edited after
    /// log time.
    var enteredUnit: UnitSystem?

    var category: DrinkCategory = DrinkCategory.beer
    var icon: String = ""

    var template: DrinkTemplate?

    var customName: String?
    var notes: String?
    var price: Double?
    /// ISO 4217 code the `price` was entered in (plan-0034). Persisted *with*
    /// the price so a stored amount is never reinterpreted when the user later
    /// changes their profile currency. nil means "unknown"; the display falls back
    /// to the profile currency. Never affects any calculation.
    var priceCurrency: String?

    /// Last-write-wins clock (plan-0023). Set to `.now` on create and on every edit;
    /// drives newer-wins conflict resolution and feeds the cross-device de-dup sweep.
    /// Inline default is a sentinel — the V1→V2 migration backfills existing rows to
    /// their `timestamp`, and `init` sets `.now` on real creation.
    var modifiedDate: Date = Date(timeIntervalSince1970: 0)

    /// Pure-alcohol mass (g) for a given density, counting every portion:
    /// `volumeMl × quantity × abv × density`. The display layer passes the active
    /// mode and guideline's `density(for:)`; physical figures (calories / BAC) pass 0.789.
    func alcoholGrams(density: Double) -> Double {
        volumeMl * Double(quantity) * abv * density
    }

    /// Physical pure-alcohol mass (scientific 0.789 density). Used for calories and
    /// future BAC — never shifts with the user's chosen display unit.
    var pureAlcoholGrams: Double {
        alcoholGrams(density: AlcoholUnit.physicalDensityGramsPerMl)
    }

    init(
        consumptionDate: Date = .now,
        volumeMl: Double,
        abv: Double,
        quantity: Int = 1,
        enteredUnit: UnitSystem? = nil,
        category: DrinkCategory,
        icon: String,
        template: DrinkTemplate? = nil,
        customName: String? = nil,
        notes: String? = nil,
        price: Double? = nil,
        priceCurrency: String? = nil,
        creationDate: Date? = nil
    ) {
        self.uuid = UUID()
        self.consumptionDate = consumptionDate
        // No explicit creation instant → mirror the consumption date (per spec).
        self.creationDate = creationDate ?? consumptionDate
        self.volumeMl = volumeMl
        self.abv = abv
        self.quantity = quantity
        self.enteredUnit = enteredUnit
        self.category = category
        self.icon = icon
        self.template = template
        self.customName = customName
        self.notes = notes
        self.price = price
        self.priceCurrency = priceCurrency
        self.modifiedDate = .now
    }

    /// Stamp the LWW clock. Call after any edit to an event's fields.
    func touch() {
        modifiedDate = .now
    }
}

extension ConsumptionEvent {
    /// A new event copying every field of this one, with a **fresh `uuid`** and
    /// `consumptionDate` reset (defaults to `.now`). Used by the History "Duplicate"
    /// action for a fast re-log — the copy is a distinct record, so it must not
    /// share identity. `creationDate` is left to the initializer, which mirrors the
    /// new `consumptionDate` (the copy is created now). The returned instance is
    /// unmanaged — the caller inserts it. The `template` reference is preserved.
    func duplicated(consumptionDate: Date = .now) -> ConsumptionEvent {
        ConsumptionEvent(
            consumptionDate: consumptionDate,
            volumeMl: volumeMl,
            abv: abv,
            quantity: quantity,
            enteredUnit: enteredUnit,
            category: category,
            icon: icon,
            template: template,
            customName: customName,
            notes: notes,
            price: price,
            priceCurrency: priceCurrency
        )
    }
}

extension ConsumptionEvent {
    /// User-facing name, resolved for `unitSystem`. Appends "×N" when more than
    /// one portion was logged. `unitSystem` is the *current profile* unit; the
    /// actual naming unit is the event's `enteredUnit` provenance when present
    /// (plan-0031 / ADR-0007), so the name stays stable across unit-mode switches.
    func displayName(in unitSystem: UnitSystem) -> String {
        let base = baseName(in: unitSystem)
        return quantity > 1 ? "\(base) ×\(quantity)" : base
    }

    /// Name-resolution chain (plan-0031):
    /// 1. an explicit `customName` always wins;
    /// 2. else resolve against the category's preset options at this `volumeMl`,
    ///    naming in `enteredUnit` when set, otherwise the current profile unit;
    /// 3. no matching preset option (orphaned/dropped serving) → `formatVolume`.
    private func baseName(in unitSystem: UnitSystem) -> String {
        if let custom = customName?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            return custom
        }
        let resolvedUnit = enteredUnit ?? unitSystem
        let preset = DrinkTypePreset.preset(for: category)
        if let match = preset.volumes.first(where: { abs($0.volumeMl - volumeMl) < 0.5 }) {
            let name = match.name(in: resolvedUnit).trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                return name
            }
        }
        return resolvedUnit.formatVolume(volumeMl)
    }
}

extension ConsumptionEvent {
    static var previewBeer: ConsumptionEvent {
        ConsumptionEvent(volumeMl: 568, abv: 0.05, category: .beer, icon: "🍺")
    }
    static var previewWine: ConsumptionEvent {
        let twoHoursAgo = Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now
        return ConsumptionEvent(consumptionDate: twoHoursAgo, volumeMl: 175, abv: 0.135,
                                category: .wine, icon: "🍷")
    }
    static var previewSpirits: ConsumptionEvent {
        let priorEvening = Calendar.current.date(byAdding: .hour, value: -20, to: .now) ?? .now
        return ConsumptionEvent(consumptionDate: priorEvening, volumeMl: 50, abv: 0.40,
                                category: .spirits, icon: "🥃")
    }
}
