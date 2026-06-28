import Foundation

/// Codable snapshot of a `DrinkTemplate` for export/import (plan-0023).
///
/// Templates gained a stable `uuid` and `modifiedDate` alongside events, so the
/// backup bundle carries them too — enabling identity-based upsert and the
/// cross-device de-dup sweep to cover both syncable models. Optional `uuid` /
/// `modifiedDate` keep the format back-compatible with bundles that never had
/// templates (the field is absent there).
nonisolated struct TemplateRecord: Codable {
    var uuid: UUID?
    var name: String
    var category: String
    var defaultVolumeMl: Double
    var abv: Double
    var icon: String
    var colorHex: String
    var isFavorite: Bool
    var isArchived: Bool
    var modifiedDate: Date?

    private enum CodingKeys: String, CodingKey {
        case uuid, name, category, defaultVolumeMl, abv, icon, colorHex
        case isFavorite, isArchived, modifiedDate
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uuid            = try c.decodeIfPresent(UUID.self, forKey: .uuid)
        name            = try c.decode(String.self, forKey: .name)
        category        = try c.decode(String.self, forKey: .category)
        defaultVolumeMl = try c.decode(Double.self, forKey: .defaultVolumeMl)
        abv             = try c.decode(Double.self, forKey: .abv)
        icon            = try c.decode(String.self, forKey: .icon)
        colorHex        = try c.decode(String.self, forKey: .colorHex)
        isFavorite      = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isArchived      = try c.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        modifiedDate    = try c.decodeIfPresent(Date.self, forKey: .modifiedDate)
    }
}

extension TemplateRecord {
    @MainActor
    init(from template: DrinkTemplate) {
        uuid            = template.uuid
        name            = template.name
        category        = template.category.rawValue
        defaultVolumeMl = template.defaultVolumeMl
        abv             = template.abv
        icon            = template.icon
        colorHex        = template.colorHex
        isFavorite      = template.isFavorite
        isArchived      = template.isArchived
        modifiedDate    = template.modifiedDate
    }

    @MainActor
    func apply(category: DrinkCategory, to template: DrinkTemplate) {
        template.name = name
        template.category = category
        template.defaultVolumeMl = defaultVolumeMl
        template.abv = abv
        template.icon = icon
        template.colorHex = colorHex
        template.isFavorite = isFavorite
        template.isArchived = isArchived
        template.modifiedDate = modifiedDate ?? .now
    }
}
