import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct SanitizedBackupFixtureTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private struct Counts: Equatable {
        let events: Int
        let templates: Int
        let profiles: Int
    }

    private func counts(in context: ModelContext) throws -> Counts {
        Counts(
            events: try context.fetch(FetchDescriptor<ConsumptionEvent>()).count,
            templates: try context.fetch(FetchDescriptor<DrinkTemplate>()).count,
            profiles: try context.fetch(FetchDescriptor<UserProfile>()).count
        )
    }

    private func exportedJSON(from context: ModelContext) throws -> String {
        let events = try context.fetch(FetchDescriptor<ConsumptionEvent>())
        let templates = try context.fetch(FetchDescriptor<DrinkTemplate>())
        let profile = try context.fetch(FetchDescriptor<UserProfile>()).first
        let data = try BackupExport(events: events, templates: templates, profile: profile).encoded()
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - Probe (synthetic export proves loading and the importer path)

    @Test func probe_loaderReturnsNonEmptyData() throws {
        let data = try BackupFixtureLoader.data(named: "probe-export-v2")
        #expect(!data.isEmpty)
    }

    @Test func probe_importsWithoutFailures_andReimportIsNoOp() throws {
        let data = try BackupFixtureLoader.data(named: "probe-export-v2")
        let container = try makeContainer()
        let context = container.mainContext

        let first = try DataImporter().importData(data, into: context)
        try context.save()
        let afterFirst = try counts(in: context)
        let second = try DataImporter().importData(data, into: context)
        try context.save()

        #expect(first.failed == 0)
        #expect(first.imported == 3)
        #expect(second.imported == 0)
        #expect(second.failed == 0)
        #expect(afterFirst == Counts(events: 3, templates: 1, profiles: 1))
        #expect(try counts(in: context) == afterFirst)
    }

    @Test func probe_exportOfImportedStoreHasNoHealthKitUUID() throws {
        let data = try BackupFixtureLoader.data(named: "probe-export-v2")
        let container = try makeContainer()
        let context = container.mainContext
        _ = try DataImporter().importData(data, into: context)
        try context.save()

        #expect(!(try exportedJSON(from: context)).contains("healthKitUUID"))
    }

    // MARK: - Sanitized fixture (owner-scrubbed, real shape; D-07, D-08, D-09)

    private static let sanitizedName = "sanitized-export-v2"

    private func sanitizedData() throws -> Data {
        try BackupFixtureLoader.data(named: Self.sanitizedName)
    }

    private func sanitizedRoot() throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: sanitizedData()) as? [String: Any])
    }

    @Test func sanitized_decodesAtVersion2_andImportsWithoutFailures() throws {
        let data = try sanitizedData()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bundle = try decoder.decode(ExportBundle.self, from: data)
        let container = try makeContainer()
        let context = container.mainContext

        let result = try DataImporter().importData(data, into: context)
        try context.save()

        #expect(bundle.version == 2)
        #expect(!bundle.events.isEmpty)
        #expect(result.failed == 0)
        #expect(result.imported == bundle.events.count)
    }

    @Test func sanitized_reimportIsNoOp() throws {
        let data = try sanitizedData()
        let container = try makeContainer()
        let context = container.mainContext

        _ = try DataImporter().importData(data, into: context)
        try context.save()
        let afterFirst = try counts(in: context)
        let second = try DataImporter().importData(data, into: context)
        try context.save()

        #expect(second.imported == 0)
        #expect(second.failed == 0)
        #expect(try counts(in: context) == afterFirst)
    }

    @Test func sanitized_exportHasNoHealthKitUUID_andOnlyAllowedKeys() throws {
        let data = try sanitizedData()
        let container = try makeContainer()
        let context = container.mainContext
        _ = try DataImporter().importData(data, into: context)
        try context.save()

        let keyFailures = Lint.keyFailures(try sanitizedRoot())
        #expect(keyFailures.isEmpty, Comment(rawValue: "Disallowed keys: \(keyFailures.joined(separator: ", "))"))
        #expect(!(try exportedJSON(from: context)).contains("healthKitUUID"))
    }

    /// Mirrors the "Allowed values" section of 10-FIXTURE-SCRUB.md. Never weaken it: if it fails, re-scrub.
    @Test func sanitized_lint_containsOnlyAllowedPlaceholderValues() throws {
        let root = try sanitizedRoot()
        let failures = Lint.failures(root)
        #expect(failures.isEmpty, Comment(rawValue: "Allowed-values violations: \(failures.joined(separator: ", "))"))
    }

    @Test func lint_rejectsPersonalValues() {
        let leaked: [String: Any] = [
            "version": 2, "exportedAt": "2025-03-01T10:11:12Z",
            "events": [["uuid": "AAAAAAAA-0000-0000-0000-000000000001", "timestamp": "2025-02-01T20:11:12Z",
                        "notes": "real", "price": 3.3, "priceCurrency": "EUR", "healthKitUUID": "x"]],
            "profile": ["bodyWeightKg": 71.3, "biologicalSex": "female", "currency": "PLN"]
        ]
        let failures = Lint.failures(leaked)
        for rule in ["exportedAt", "date-window", "uuid", "notes", "price", "priceCurrency",
                     "bodyWeightKg", "biologicalSex", "currency", "key"] {
            #expect(failures.contains { $0.hasPrefix(rule + "@") }, Comment(rawValue: "lint missed rule \(rule)"))
        }
    }
}

private enum Lint {
    typealias JSON = [String: Any]

    static let base = ISO8601DateFormatter().date(from: "2026-01-05T09:00:00Z")!
    static let exportedAt = "2026-01-15T12:00:00Z"
    static let fixedModified = "2026-01-05T09:00:00Z"
    static let dateOfBirth = "1990-01-01T00:00:00Z"
    static let eventUUIDPrefix = "00000000-0000-4000-8000-"
    static let templateUUIDPrefix = "00000000-0000-4000-9000-"
    static let prices: Set<Double> = [1.0, 2.5, 5.0, 10.0]
    static let maxEvents = 14
    static let maxTemplates = 6

    static let topKeys: Set<String> = ["version", "exportedAt", "events", "templates", "profile"]
    static let eventKeys: Set<String> = [
        "uuid", "timestamp", "creationDate", "volumeMl", "abv", "quantity", "enteredUnit", "category",
        "icon", "customName", "notes", "price", "priceCurrency", "modifiedDate"
    ]
    static let templateKeys: Set<String> = [
        "uuid", "name", "category", "defaultVolumeMl", "abv", "icon", "colorHex", "isFavorite",
        "isArchived", "modifiedDate"
    ]
    static let profileKeys: Set<String> = [
        "bodyWeightKg", "biologicalSex", "dateOfBirth", "guidelineChoice", "weeklyGoalGrams", "unitSystem",
        "currency", "abvPrecisionPermille", "alcoholUnit", "modifiedDate"
    ]

    /// A present, non-null value; JSON null counts as absent.
    static func value(_ dict: JSON, _ key: String) -> Any? {
        let v = dict[key]
        return v is NSNull ? nil : v
    }

    /// `base` plus `day` days plus 0...119 whole minutes, zero seconds.
    static func inWindow(_ any: Any?, day: Int) -> Bool {
        guard let text = any as? String, let date = ISO8601DateFormatter().date(from: text) else { return false }
        let offset = date.timeIntervalSince(base) - Double(day) * 86_400
        return offset >= 0 && offset <= 119 * 60 && offset.truncatingRemainder(dividingBy: 60) == 0
    }

    static func isUUID(_ any: Any?, prefix: String, number: Int) -> Bool {
        (any as? String) == prefix + String(format: "%012d", number)
    }

    /// `prefix` followed by one or more ASCII digits only.
    static func isPlaceholder(_ any: Any?, prefix: String) -> Bool {
        guard let text = any as? String, text.hasPrefix(prefix) else { return false }
        let digits = text.dropFirst(prefix.count)
        return !digits.isEmpty && digits.allSatisfy { ("0"..."9").contains($0) }
    }

    static func extraKeys(_ dict: JSON, allowed: Set<String>) -> Bool {
        !Set(dict.keys).isSubset(of: allowed)
    }

    static func keyFailures(_ root: JSON) -> [String] {
        var out: [String] = []
        if extraKeys(root, allowed: topKeys) { out.append("key@top") }
        for (i, e) in ((root["events"] as? [JSON]) ?? []).enumerated() where extraKeys(e, allowed: eventKeys) {
            out.append("key@event\(i)")
        }
        for (i, t) in ((root["templates"] as? [JSON]) ?? []).enumerated() where extraKeys(t, allowed: templateKeys) {
            out.append("key@template\(i)")
        }
        if let p = root["profile"] as? JSON, extraKeys(p, allowed: profileKeys) { out.append("key@profile") }
        return out
    }

    static func failures(_ root: JSON) -> [String] {
        var out = keyFailures(root)
        let events = (root["events"] as? [JSON]) ?? []
        let templates = (root["templates"] as? [JSON]) ?? []
        if (root["exportedAt"] as? String) != exportedAt { out.append("exportedAt@top") }
        if events.count > maxEvents { out.append("eventCount@top") }
        if templates.count > maxTemplates { out.append("templateCount@top") }
        for (r, e) in events.enumerated() { out += eventFailures(e, position: r) }
        for (i, t) in templates.enumerated() { out += templateFailures(t, position: i + 1) }
        if let p = root["profile"] as? JSON { out += profileFailures(p) }
        return out
    }

    static func eventFailures(_ e: JSON, position r: Int) -> [String] {
        var out: [String] = []
        func check(_ ok: Bool, _ rule: String) { if !ok { out.append("\(rule)@event\(r)") } }
        for key in ["timestamp", "creationDate", "modifiedDate"] where key == "timestamp" || value(e, key) != nil {
            check(inWindow(value(e, key), day: r), "date-window")
        }
        if let u = value(e, "uuid") { check(isUUID(u, prefix: eventUUIDPrefix, number: r + 1), "uuid") }
        if let n = value(e, "customName") { check(isPlaceholder(n, prefix: "name-"), "customName") }
        if let n = value(e, "notes") { check(isPlaceholder(n, prefix: "note-"), "notes") }
        if let p = value(e, "price") { check((p as? Double).map(prices.contains) ?? false, "price") }
        if let c = value(e, "priceCurrency") { check((c as? String) == "USD", "priceCurrency") }
        return out
    }

    static func templateFailures(_ t: JSON, position n: Int) -> [String] {
        var out: [String] = []
        func check(_ ok: Bool, _ rule: String) { if !ok { out.append("\(rule)@template\(n)") } }
        if let u = value(t, "uuid") { check(isUUID(u, prefix: templateUUIDPrefix, number: n), "uuid") }
        if let name = value(t, "name") { check(isPlaceholder(name, prefix: "template-"), "name") }
        if let m = value(t, "modifiedDate") { check((m as? String) == fixedModified, "modifiedDate") }
        return out
    }

    static func profileFailures(_ p: JSON) -> [String] {
        var out: [String] = []
        func check(_ ok: Bool, _ rule: String) { if !ok { out.append("\(rule)@profile") } }
        check((value(p, "bodyWeightKg") as? Double) == 80.0, "bodyWeightKg")
        check((value(p, "weeklyGoalGrams") as? Double) == 100.0, "weeklyGoalGrams")
        check((value(p, "guidelineChoice") as? String) == "who", "guidelineChoice")
        check((value(p, "biologicalSex") as? String) == "male", "biologicalSex")
        check((value(p, "currency") as? String) == "USD", "currency")
        if let d = value(p, "dateOfBirth") { check((d as? String) == dateOfBirth, "dateOfBirth") }
        if let m = value(p, "modifiedDate") { check((m as? String) == fixedModified, "modifiedDate") }
        return out
    }
}
