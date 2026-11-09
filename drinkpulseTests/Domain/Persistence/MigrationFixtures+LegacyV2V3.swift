import Foundation
import SwiftData
@testable import drinkpulse

// V2 and V3 seeds. SchemaV2/V3 types expose only init(), so each record is
// constructed first and its properties are assigned afterwards. UUIDs and
// dates are explicit so a test can prove they survive the migration exactly.

struct LegacyEventExpectation {
    let uuid: UUID
    let consumptionDate: Date
    /// What the live store must hold: derived from consumptionDate for a V2 seed
    /// (V2 had no creationDate), the seeded value for a V3 seed.
    let creationDate: Date
    let modifiedDate: Date
    let values: EventValues
}

struct LegacyExpectation {
    let profile: ProfileValues
    let profileModifiedDate: Date
    let template: TemplateValues
    let templateUUID: UUID
    let templateModifiedDate: Date
    let linked: LegacyEventExpectation
    let plain: LegacyEventExpectation
}

typealias V2Expectation = LegacyExpectation
typealias V3Expectation = LegacyExpectation

extension MigrationFixtures {

    static let legacyProfileValues = ProfileValues(
        bodyWeightKg: 82.25, biologicalSex: .male,
        dateOfBirth: Date(timeIntervalSince1970: 600_000), guidelineChoice: .de,
        weeklyGoalGrams: 140, unitSystem: .usCustomary, currency: "EUR",
        abvPrecisionPermille: 2, alcoholUnit: .grams
    )

    static let legacyTemplateValues = TemplateValues(
        name: "Stout", category: .beer, defaultVolumeMl: 440, abv: 0.052,
        icon: "mug.fill", colorHex: "#3B2F2F", isFavorite: true, isArchived: true
    )

    static let legacyLinkedEventValues = EventValues(
        volumeMl: 473, abv: 0.06, quantity: 2, enteredUnit: .usCustomary, category: .beer,
        icon: "🍺", customName: "Pint", notes: "Pub", price: 6.25, priceCurrency: "USD"
    )

    static let legacyPlainEventValues = EventValues(
        volumeMl: 150, abv: 0.135, quantity: 1, enteredUnit: nil, category: .wine,
        icon: "🍷", customName: nil, notes: nil, price: nil, priceCurrency: nil
    )

    private static func expectation(
        consumptionBase: TimeInterval, creationOffset: TimeInterval?, modifiedBase: TimeInterval
    ) -> LegacyExpectation {
        func event(_ index: TimeInterval, _ values: EventValues) -> LegacyEventExpectation {
            let consumption = Date(timeIntervalSince1970: consumptionBase + index * 60)
            return LegacyEventExpectation(
                uuid: UUID(), consumptionDate: consumption,
                creationDate: creationOffset.map { consumption.addingTimeInterval($0) } ?? consumption,
                modifiedDate: Date(timeIntervalSince1970: modifiedBase + index * 60), values: values
            )
        }
        return LegacyExpectation(
            profile: legacyProfileValues,
            profileModifiedDate: Date(timeIntervalSince1970: modifiedBase + 200),
            template: legacyTemplateValues, templateUUID: UUID(),
            templateModifiedDate: Date(timeIntervalSince1970: modifiedBase + 100),
            linked: event(0, legacyLinkedEventValues), plain: event(1, legacyPlainEventValues)
        )
    }

    // MARK: - V2

    static func seedV2Store(at url: URL) throws -> V2Expectation {
        let exp = expectation(consumptionBase: 1_700_000, creationOffset: nil, modifiedBase: 1_700_500)
        let schema = Schema(versionedSchema: SchemaV2.self)
        let container = try ModelContainer(
            for: schema, configurations: [ModelConfiguration(schema: schema, url: url)]
        )
        let context = container.mainContext

        let profile = SchemaV2.UserProfile()
        let p = exp.profile
        profile.bodyWeightKg = p.bodyWeightKg
        profile.biologicalSex = p.biologicalSex
        profile.dateOfBirth = p.dateOfBirth
        profile.guidelineChoice = p.guidelineChoice
        profile.weeklyGoalGrams = p.weeklyGoalGrams
        profile.unitSystem = p.unitSystem
        profile.currency = p.currency
        profile.abvPrecisionPermille = p.abvPrecisionPermille
        profile.alcoholUnit = p.alcoholUnit
        profile.modifiedDate = exp.profileModifiedDate

        let template = SchemaV2.DrinkTemplate()
        let t = exp.template
        template.uuid = exp.templateUUID
        template.name = t.name
        template.category = t.category
        template.defaultVolumeMl = t.defaultVolumeMl
        template.abv = t.abv
        template.icon = t.icon
        template.colorHex = t.colorHex
        template.isFavorite = t.isFavorite
        template.isArchived = t.isArchived
        template.modifiedDate = exp.templateModifiedDate

        func makeEvent(_ e: LegacyEventExpectation, linkedTo: SchemaV2.DrinkTemplate?) -> SchemaV2.ConsumptionEvent {
            let event = SchemaV2.ConsumptionEvent()
            event.uuid = e.uuid
            event.timestamp = e.consumptionDate
            event.volumeMl = e.values.volumeMl
            event.abv = e.values.abv
            event.quantity = e.values.quantity
            event.enteredUnit = e.values.enteredUnit
            event.category = e.values.category
            event.icon = e.values.icon
            event.template = linkedTo
            event.customName = e.values.customName
            event.notes = e.values.notes
            event.price = e.values.price
            event.priceCurrency = e.values.priceCurrency
            event.modifiedDate = e.modifiedDate
            return event
        }

        context.insert(profile)
        context.insert(template)
        context.insert(makeEvent(exp.linked, linkedTo: template))
        context.insert(makeEvent(exp.plain, linkedTo: nil))
        try context.save()
        return exp
    }

    // MARK: - V3

    static func seedV3Store(at url: URL) throws -> V3Expectation {
        let exp = expectation(consumptionBase: 1_800_000, creationOffset: -3_600, modifiedBase: 1_800_500)
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(
            for: schema, configurations: [ModelConfiguration(schema: schema, url: url)]
        )
        let context = container.mainContext

        let profile = SchemaV3.UserProfile()
        let p = exp.profile
        profile.bodyWeightKg = p.bodyWeightKg
        profile.biologicalSex = p.biologicalSex
        profile.dateOfBirth = p.dateOfBirth
        profile.guidelineChoice = p.guidelineChoice
        profile.weeklyGoalGrams = p.weeklyGoalGrams
        profile.unitSystem = p.unitSystem
        profile.currency = p.currency
        profile.abvPrecisionPermille = p.abvPrecisionPermille
        profile.alcoholUnit = p.alcoholUnit
        profile.modifiedDate = exp.profileModifiedDate

        let template = SchemaV3.DrinkTemplate()
        let t = exp.template
        template.uuid = exp.templateUUID
        template.name = t.name
        template.category = t.category
        template.defaultVolumeMl = t.defaultVolumeMl
        template.abv = t.abv
        template.icon = t.icon
        template.colorHex = t.colorHex
        template.isFavorite = t.isFavorite
        template.isArchived = t.isArchived
        template.modifiedDate = exp.templateModifiedDate

        func makeEvent(_ e: LegacyEventExpectation, linkedTo: SchemaV3.DrinkTemplate?) -> SchemaV3.ConsumptionEvent {
            let event = SchemaV3.ConsumptionEvent()
            event.uuid = e.uuid
            event.consumptionDate = e.consumptionDate
            event.creationDate = e.creationDate
            event.volumeMl = e.values.volumeMl
            event.abv = e.values.abv
            event.quantity = e.values.quantity
            event.enteredUnit = e.values.enteredUnit
            event.category = e.values.category
            event.icon = e.values.icon
            event.template = linkedTo
            event.customName = e.values.customName
            event.notes = e.values.notes
            event.price = e.values.price
            event.priceCurrency = e.values.priceCurrency
            event.modifiedDate = e.modifiedDate
            return event
        }

        context.insert(profile)
        context.insert(template)
        context.insert(makeEvent(exp.linked, linkedTo: template))
        context.insert(makeEvent(exp.plain, linkedTo: nil))
        try context.save()
        return exp
    }
}
