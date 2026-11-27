import Foundation
import SwiftData
@testable import drinkpulse

// Plain-value mirrors of the stored properties of each live model. They let a
// test compare a migrated record against what was seeded (or against an earlier
// snapshot of the same store) without holding SwiftData objects across opens.
// All values used with these types are synthetic.

struct ProfileValues: Equatable {
    var bodyWeightKg: Double
    var biologicalSex: BiologicalSex
    var guidelineChoice: GuidelineChoice
    var weeklyGoalGrams: Double
    var unitSystem: UnitSystem
    var currency: String
    var abvPrecisionPermille: Int
    var alcoholUnit: AlcoholUnit

    init(
        bodyWeightKg: Double, biologicalSex: BiologicalSex, guidelineChoice: GuidelineChoice, weeklyGoalGrams: Double, unitSystem: UnitSystem,
        currency: String, abvPrecisionPermille: Int, alcoholUnit: AlcoholUnit
    ) {
        self.bodyWeightKg = bodyWeightKg
        self.biologicalSex = biologicalSex
        self.guidelineChoice = guidelineChoice
        self.weeklyGoalGrams = weeklyGoalGrams
        self.unitSystem = unitSystem
        self.currency = currency
        self.abvPrecisionPermille = abvPrecisionPermille
        self.alcoholUnit = alcoholUnit
    }

    init(_ profile: UserProfile) {
        self.init(
            bodyWeightKg: profile.bodyWeightKg, biologicalSex: profile.biologicalSex,
            guidelineChoice: profile.guidelineChoice,
            weeklyGoalGrams: profile.weeklyGoalGrams, unitSystem: profile.unitSystem,
            currency: profile.currency, abvPrecisionPermille: profile.abvPrecisionPermille,
            alcoholUnit: profile.alcoholUnit
        )
    }
}

struct TemplateValues: Equatable {
    var name: String
    var category: DrinkCategory
    var defaultVolumeMl: Double
    var abv: Double
    var icon: String
    var colorHex: String
    var isFavorite: Bool
    var isArchived: Bool

    init(
        name: String, category: DrinkCategory, defaultVolumeMl: Double, abv: Double,
        icon: String, colorHex: String, isFavorite: Bool, isArchived: Bool
    ) {
        self.name = name
        self.category = category
        self.defaultVolumeMl = defaultVolumeMl
        self.abv = abv
        self.icon = icon
        self.colorHex = colorHex
        self.isFavorite = isFavorite
        self.isArchived = isArchived
    }

    init(_ template: DrinkTemplate) {
        self.init(
            name: template.name, category: template.category,
            defaultVolumeMl: template.defaultVolumeMl, abv: template.abv, icon: template.icon,
            colorHex: template.colorHex, isFavorite: template.isFavorite,
            isArchived: template.isArchived
        )
    }
}

struct EventValues: Equatable {
    var volumeMl: Double
    var abv: Double
    var quantity: Int
    var enteredUnit: UnitSystem?
    var category: DrinkCategory
    var icon: String
    var customName: String?
    var notes: String?
    var price: Double?
    var priceCurrency: String?

    init(
        volumeMl: Double, abv: Double, quantity: Int, enteredUnit: UnitSystem?,
        category: DrinkCategory, icon: String, customName: String?, notes: String?,
        price: Double?, priceCurrency: String?
    ) {
        self.volumeMl = volumeMl
        self.abv = abv
        self.quantity = quantity
        self.enteredUnit = enteredUnit
        self.category = category
        self.icon = icon
        self.customName = customName
        self.notes = notes
        self.price = price
        self.priceCurrency = priceCurrency
    }

    init(_ event: ConsumptionEvent) {
        self.init(
            volumeMl: event.volumeMl, abv: event.abv, quantity: event.quantity,
            enteredUnit: event.enteredUnit, category: event.category, icon: event.icon,
            customName: event.customName, notes: event.notes, price: event.price,
            priceCurrency: event.priceCurrency
        )
    }
}

// MARK: - Full-store snapshot (every stored property, identities and clocks included)

struct EventSnapshot: Equatable {
    let uuid: UUID
    let consumptionDate: Date
    let creationDate: Date
    let modifiedDate: Date
    let healthKitUUID: UUID?
    let templateUUID: UUID?
    let values: EventValues
}

struct TemplateSnapshot: Equatable {
    let uuid: UUID
    let modifiedDate: Date
    let eventUUIDs: Set<UUID>
    let values: TemplateValues
}

struct ProfileSnapshot: Equatable {
    let id: String
    let modifiedDate: Date
    let values: ProfileValues
}

struct StoreSnapshot: Equatable {
    let eventCount: Int
    let templateCount: Int
    let profileCount: Int
    let events: [UUID: EventSnapshot]
    let templates: [UUID: TemplateSnapshot]
    let profiles: [ProfileSnapshot]

    @MainActor
    static func take(from context: ModelContext) throws -> StoreSnapshot {
        let events = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        let templates = try context.fetch(FetchDescriptor<DrinkTemplate>())
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        return StoreSnapshot(
            eventCount: events.count,
            templateCount: templates.count,
            profileCount: profiles.count,
            events: Dictionary(events.map { ($0.uuid, EventSnapshot($0)) }, uniquingKeysWith: { first, _ in first }),
            templates: Dictionary(templates.map { ($0.uuid, TemplateSnapshot($0)) }, uniquingKeysWith: { first, _ in first }),
            profiles: profiles.map(ProfileSnapshot.init)
        )
    }
}

extension EventSnapshot {
    init(_ event: ConsumptionEvent) {
        self.init(
            uuid: event.uuid, consumptionDate: event.consumptionDate,
            creationDate: event.creationDate, modifiedDate: event.modifiedDate,
            healthKitUUID: event.healthKitUUID, templateUUID: event.template?.uuid,
            values: EventValues(event)
        )
    }
}

extension TemplateSnapshot {
    init(_ template: DrinkTemplate) {
        self.init(
            uuid: template.uuid, modifiedDate: template.modifiedDate,
            eventUUIDs: Set(template.events.map(\.uuid)), values: TemplateValues(template)
        )
    }
}

extension ProfileSnapshot {
    init(_ profile: UserProfile) {
        self.init(id: profile.id, modifiedDate: profile.modifiedDate, values: ProfileValues(profile))
    }
}
