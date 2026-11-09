import Foundation
import SwiftData
@testable import drinkpulse

// Seeds legacy stores from the frozen SchemaV1/V2/V3 snapshots so a test can
// reopen them under MigrationPlan. Every value is synthetic. Each seed builds a
// plain ModelContainer for the frozen schema and releases it before returning,
// so the store file is closed when the caller reopens it.

struct V1Expectation {
    let profile: ProfileValues
    let template: TemplateValues
    let eventA: EventValues
    let eventB: EventValues
    let timestampA: Date
    let timestampB: Date
}

@MainActor
enum MigrationFixtures {

    static func makeTempStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
    }

    static func removeStoreFiles(at url: URL) {
        let fm = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let file = url.deletingPathExtension()
                .appendingPathExtension(url.pathExtension + suffix)
            try? fm.removeItem(at: file)
        }
    }

    static func liveSchema() -> Schema {
        Schema([DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self])
    }

    static func liveConfiguration(at url: URL) -> ModelConfiguration {
        ModelConfiguration(schema: liveSchema(), url: url)
    }

    // MARK: - V1

    static let v1ProfileValues = ProfileValues(
        bodyWeightKg: 77.5, biologicalSex: .female,
        dateOfBirth: Date(timeIntervalSince1970: 500_000), guidelineChoice: .uk,
        weeklyGoalGrams: 112, unitSystem: .imperial, currency: "GBP",
        abvPrecisionPermille: 1, alcoholUnit: .grams
    )

    static let v1TemplateValues = TemplateValues(
        name: "Lager", category: .beer, defaultVolumeMl: 500, abv: 0.05,
        icon: "mug.fill", colorHex: "#F5A623", isFavorite: true, isArchived: true
    )

    static let v1TimestampA = Date(timeIntervalSince1970: 1_234_567)
    static let v1TimestampB = Date(timeIntervalSince1970: 1_234_627)

    static let v1EventAValues = EventValues(
        volumeMl: 568, abv: 0.05, quantity: 3, enteredUnit: .imperial, category: .beer,
        icon: "🍺", customName: "Pint", notes: "Pub", price: 5.40, priceCurrency: "GBP"
    )

    static let v1EventBValues = EventValues(
        volumeMl: 330, abv: 0.045, quantity: 1, enteredUnit: nil, category: .cider,
        icon: "🍎", customName: nil, notes: nil, price: nil, priceCurrency: nil
    )

    static func seedV1Store(at url: URL) throws -> V1Expectation {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let container = try ModelContainer(
            for: schema, configurations: [ModelConfiguration(schema: schema, url: url)]
        )
        let context = container.mainContext
        let p = v1ProfileValues
        let profile = SchemaV1.UserProfile(
            bodyWeightKg: p.bodyWeightKg, biologicalSex: p.biologicalSex,
            dateOfBirth: p.dateOfBirth, guidelineChoice: p.guidelineChoice,
            weeklyGoalGrams: p.weeklyGoalGrams, unitSystem: p.unitSystem, currency: p.currency,
            abvPrecisionPermille: p.abvPrecisionPermille, alcoholUnit: p.alcoholUnit
        )
        let t = v1TemplateValues
        let template = SchemaV1.DrinkTemplate(
            name: t.name, category: t.category, defaultVolumeMl: t.defaultVolumeMl, abv: t.abv,
            icon: t.icon, colorHex: t.colorHex, isFavorite: t.isFavorite, isArchived: t.isArchived
        )
        context.insert(profile)
        context.insert(template)
        context.insert(v1Event(v1EventAValues, at: v1TimestampA, template: template))
        context.insert(v1Event(v1EventBValues, at: v1TimestampB, template: nil))
        try context.save()
        return V1Expectation(
            profile: p, template: t, eventA: v1EventAValues, eventB: v1EventBValues,
            timestampA: v1TimestampA, timestampB: v1TimestampB
        )
    }

    /// One profile, one template and three events that share every field value
    /// (two of them share the timestamp too), so identity can only come from uuid.
    static func seedV1IdenticalEventsStore(at url: URL) throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let container = try ModelContainer(
            for: schema, configurations: [ModelConfiguration(schema: schema, url: url)]
        )
        let context = container.mainContext
        context.insert(SchemaV1.UserProfile(bodyWeightKg: 70, biologicalSex: .male))
        let t = v1TemplateValues
        context.insert(SchemaV1.DrinkTemplate(
            name: t.name, category: t.category, defaultVolumeMl: t.defaultVolumeMl, abv: t.abv,
            icon: t.icon, colorHex: t.colorHex
        ))
        let same = EventValues(
            volumeMl: 500, abv: 0.05, quantity: 1, enteredUnit: nil, category: .beer,
            icon: "🍺", customName: nil, notes: nil, price: nil, priceCurrency: nil
        )
        let stamp = Date(timeIntervalSince1970: 2_000_000)
        context.insert(v1Event(same, at: stamp, template: nil))
        context.insert(v1Event(same, at: stamp, template: nil))
        context.insert(v1Event(same, at: stamp.addingTimeInterval(60), template: nil))
        try context.save()
    }

    private static func v1Event(
        _ v: EventValues, at stamp: Date, template: SchemaV1.DrinkTemplate?
    ) -> SchemaV1.ConsumptionEvent {
        SchemaV1.ConsumptionEvent(
            timestamp: stamp, volumeMl: v.volumeMl, abv: v.abv, quantity: v.quantity,
            enteredUnit: v.enteredUnit, name: "Beer", category: v.category, icon: v.icon,
            template: template, customName: v.customName, notes: v.notes, price: v.price,
            priceCurrency: v.priceCurrency
        )
    }
}
