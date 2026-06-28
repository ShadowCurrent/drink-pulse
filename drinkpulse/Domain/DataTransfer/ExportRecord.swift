import Foundation

nonisolated struct ExportRecord: Codable {
    /// Stable identity (plan-0023). Optional for back-compat: backups written
    /// before identity existed have no `uuid` → decodes nil, and the importer
    /// falls back to the (timestamp, volume, abv, quantity) duplicate heuristic.
    var uuid: UUID?
    var timestamp: Date
    var volumeMl: Double
    var abv: Double
    /// Number of single portions in this log. Absent in files written before
    /// plan-0025 → decodes to 1 (those files folded the count into `volumeMl`).
    var quantity: Int
    /// Unit-system provenance (plan-0031 / ADR-0007). Raw `UnitSystem` value, or
    /// nil. Absent in pre-plan-0031 backups → decodes to nil. Back-compatible.
    var enteredUnit: String?
    var category: String
    var icon: String
    var customName: String?
    var notes: String?
    var price: Double?
    /// ISO 4217 code the price was entered in (plan-0034). Absent in pre-plan-0034
    /// backups → decodes to nil. Back-compatible, optional key.
    var priceCurrency: String?
    /// LWW clock (plan-0023). Optional for back-compat: pre-identity backups have
    /// none → decodes nil, and the importer treats such a record as oldest.
    var modifiedDate: Date?

    private enum CodingKeys: String, CodingKey {
        case uuid, timestamp, volumeMl, abv, quantity, enteredUnit, category, icon
        case customName, notes, price, priceCurrency, modifiedDate
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uuid        = try c.decodeIfPresent(UUID.self, forKey: .uuid)
        timestamp   = try c.decode(Date.self, forKey: .timestamp)
        volumeMl    = try c.decode(Double.self, forKey: .volumeMl)
        abv         = try c.decode(Double.self, forKey: .abv)
        quantity    = try c.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        enteredUnit = try c.decodeIfPresent(String.self, forKey: .enteredUnit)
        category    = try c.decode(String.self, forKey: .category)
        icon        = try c.decode(String.self, forKey: .icon)
        customName  = try c.decodeIfPresent(String.self, forKey: .customName)
        notes       = try c.decodeIfPresent(String.self, forKey: .notes)
        price       = try c.decodeIfPresent(Double.self, forKey: .price)
        priceCurrency = try c.decodeIfPresent(String.self, forKey: .priceCurrency)
        modifiedDate = try c.decodeIfPresent(Date.self, forKey: .modifiedDate)
        // The deprecated `name` key (present in pre-plan-0023 backups) is simply
        // not in CodingKeys, so JSONDecoder ignores it. No migration needed.
    }
}

extension ExportRecord {
    @MainActor
    init(from event: ConsumptionEvent) {
        uuid        = event.uuid
        timestamp   = event.timestamp
        volumeMl    = event.volumeMl
        abv         = event.abv
        quantity    = event.quantity
        enteredUnit = event.enteredUnit?.rawValue
        category   = event.category.rawValue
        icon       = event.icon
        customName = event.customName
        notes      = event.notes
        price      = event.price
        priceCurrency = event.priceCurrency
        modifiedDate = event.modifiedDate
    }
}
