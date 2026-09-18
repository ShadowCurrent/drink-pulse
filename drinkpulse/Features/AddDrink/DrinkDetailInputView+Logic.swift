import Foundation
import SwiftData
import SwiftUI

// MARK: - Pure math helpers (unit-testable without SwiftUI)

nonisolated enum DrinkMassCalculator {
    static func massGrams(volumeMl: Double, count: Int, abv: Double, density: Double) -> Double {
        volumeMl * Double(count) * abv * density
    }

    static func nearestVolumeMl(to target: Double, in options: [DrinkTypePreset.VolumeOption]) -> Double? {
        options.min(by: { abs($0.volumeMl - target) < abs($1.volumeMl - target) })?.volumeMl
    }
}

// MARK: - DrinkDetailInputView non-trivial logic

extension DrinkDetailInputView {

    var previewMassGrams: Double {
        DrinkMassCalculator.massGrams(
            volumeMl: selectedVolumeMl,
            count: count,
            abv: selectedABV,
            density: alcoholUnit.density(for: guideline)
        )
    }

    func resolveVolumeForUnit() {
        if let nearest = DrinkMassCalculator.nearestVolumeMl(to: volumeMl, in: volumeOptions) {
            volumeMl = nearest
        }
    }

    func syncAbvValues() {
        let values = DrinkTypePreset.abvRange(
            from: Int((preset.abvMin * 1000).rounded()),
            through: Int((preset.abvMax * 1000).rounded()),
            step: abvStepPermille
        )
        guard values != abvValues else { return }
        abvValues = values
        if let nearest = values.min(by: { abs($0 - abvValue) < abs($1 - abvValue) }) {
            abvValue = nearest
        }
    }

    var parsedPrice: Double? {
        let normalized = priceText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    func save() {
        let trimmedNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCustomName = customNameText.trimmingCharacters(in: .whitespacesAndNewlines)
        let event = ConsumptionEvent(
            consumptionDate: date,
            volumeMl: selectedVolumeMl,
            abv: selectedABV,
            quantity: count,
            enteredUnit: unitSystem,
            category: preset.category,
            icon: preset.icon,
            customName: trimmedCustomName.isEmpty ? nil : trimmedCustomName,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            price: parsedPrice,
            priceCurrency: parsedPrice == nil ? nil : priceCurrency
        )
        modelContext.insert(event)
        RecordDeduplicator.ensureUniqueIdentity(event, in: modelContext)
        HealthWriteHooks.write(event, in: modelContext, using: healthService)
        dismissSheet()
    }
}
