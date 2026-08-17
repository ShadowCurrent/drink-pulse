import Foundation

nonisolated struct ExportRecord: Codable {
    var uuid: UUID?
    var consumptionDate: Date
    var creationDate: Date?
    var volumeMl: Double
    var abv: Double
    var quantity: Int
    var enteredUnit: String?
    var category: String
    var icon: String
    var customName: String?
    var notes: String?
    var price: Double?
    var priceCurrency: String?
    var modifiedDate: Date?

    private enum CodingKeys: String, CodingKey {
        case uuid
        case consumptionDate = "timestamp"
        case creationDate
        case volumeMl, abv, quantity, enteredUnit, category, icon
        case customName, notes, price, priceCurrency, modifiedDate
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uuid        = try c.decodeIfPresent(UUID.self, forKey: .uuid)
        consumptionDate = try c.decode(Date.self, forKey: .consumptionDate)
        creationDate = try c.decodeIfPresent(Date.self, forKey: .creationDate)
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
    }
}

extension ExportRecord {
    @MainActor
    init(from event: ConsumptionEvent) {
        uuid        = event.uuid
        consumptionDate = event.consumptionDate
        creationDate = event.creationDate
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
