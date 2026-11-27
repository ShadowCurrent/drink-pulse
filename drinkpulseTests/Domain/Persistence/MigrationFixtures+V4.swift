import Foundation
import SwiftData
@testable import drinkpulse

// V4 seed (quick 261127-l7y). SchemaV4 is the shipped shape with a stored date of
// birth and an event healthKitUUID; V5 drops the date of birth. Every value is
// synthetic. Like the V2/V3 seeds, records are built with init() and assigned.

struct V4Expectation {
    let profile: ProfileValues
    let profileModifiedDate: Date
    let dateOfBirth: Date
    let template: TemplateValues
    let templateUUID: UUID
    let templateModifiedDate: Date
    let linked: LegacyEventExpectation
    let plain: LegacyEventExpectation
    /// Set on the linked event only; the plain event keeps nil.
    let linkedHealthKitUUID: UUID
}

extension MigrationFixtures {

    static let v4DateOfBirth = Date(timeIntervalSince1970: 700_000)

    static func seedV4Store(at url: URL) throws -> V4Expectation {
        func event(_ index: TimeInterval, _ values: EventValues) -> LegacyEventExpectation {
            let consumption = Date(timeIntervalSince1970: 1_900_000 + index * 60)
            return LegacyEventExpectation(
                uuid: UUID(), consumptionDate: consumption,
                creationDate: consumption.addingTimeInterval(-1_800),
                modifiedDate: Date(timeIntervalSince1970: 1_900_500 + index * 60), values: values
            )
        }
        let exp = V4Expectation(
            profile: legacyProfileValues,
            profileModifiedDate: Date(timeIntervalSince1970: 1_900_700),
            dateOfBirth: v4DateOfBirth,
            template: legacyTemplateValues, templateUUID: UUID(),
            templateModifiedDate: Date(timeIntervalSince1970: 1_900_600),
            linked: event(0, legacyLinkedEventValues), plain: event(1, legacyPlainEventValues),
            linkedHealthKitUUID: UUID()
        )

        let schema = Schema(versionedSchema: SchemaV4.self)
        let container = try ModelContainer(
            for: schema, configurations: [ModelConfiguration(schema: schema, url: url)]
        )
        let context = container.mainContext

        let profile = SchemaV4.UserProfile()
        let p = exp.profile
        profile.bodyWeightKg = p.bodyWeightKg
        profile.biologicalSex = p.biologicalSex
        profile.dateOfBirth = exp.dateOfBirth
        profile.guidelineChoice = p.guidelineChoice
        profile.weeklyGoalGrams = p.weeklyGoalGrams
        profile.unitSystem = p.unitSystem
        profile.currency = p.currency
        profile.abvPrecisionPermille = p.abvPrecisionPermille
        profile.alcoholUnit = p.alcoholUnit
        profile.modifiedDate = exp.profileModifiedDate

        let template = SchemaV4.DrinkTemplate()
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

        func makeEvent(_ e: LegacyEventExpectation, linkedTo: SchemaV4.DrinkTemplate?,
                       healthKitUUID: UUID?) -> SchemaV4.ConsumptionEvent {
            let event = SchemaV4.ConsumptionEvent()
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
            event.healthKitUUID = healthKitUUID
            return event
        }

        context.insert(profile)
        context.insert(template)
        context.insert(makeEvent(exp.linked, linkedTo: template, healthKitUUID: exp.linkedHealthKitUUID))
        context.insert(makeEvent(exp.plain, linkedTo: nil, healthKitUUID: nil))
        try context.save()
        return exp
    }
}
