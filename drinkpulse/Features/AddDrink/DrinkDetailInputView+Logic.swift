import Foundation
import SwiftData

// MARK: - Pure math helpers (unit-testable without SwiftUI)

/// Stateless helpers for drink-mass and volume-resolution calculations.
/// All methods take plain values so they can be exercised directly by unit tests.
nonisolated enum DrinkMassCalculator {
    /// Display-mode mass of pure alcohol in grams.
    ///
    /// - Parameters:
    ///   - volumeMl: Portion volume in millilitres.
    ///   - count: Number of identical portions (quantity).
    ///   - abv: Alcohol by volume as a plain fraction (0.05 = 5 %).
    ///   - density: Display-mode density in g/ml from `AlcoholUnit.density(for:)`.
    ///     Physical density (0.789) is only correct when the user chose `.grams`.
    /// - Returns: Mass in grams for the active display unit.
    ///
    /// Hand-verify before changing — see CLAUDE.md Calculations section.
    static func massGrams(volumeMl: Double, count: Int, abv: Double, density: Double) -> Double {
        volumeMl * Double(count) * abv * density
    }

    /// Nearest `volumeMl` to `target` among `options`.
    ///
    /// - Returns: The matching value, or `nil` when `options` is empty.
    static func nearestVolumeMl(to target: Double, in options: [DrinkTypePreset.VolumeOption]) -> Double? {
        options.min(by: { abs($0.volumeMl - target) < abs($1.volumeMl - target) })?.volumeMl
    }
}

// MARK: - DrinkDetailInputView non-trivial logic

extension DrinkDetailInputView {

    // Live preview mass in the user's display unit (density depends on the chosen mode
    // and guideline — see AlcoholUnit.density(for:)). Hand-verify before changing.
    var previewMassGrams: Double {
        DrinkMassCalculator.massGrams(
            volumeMl: selectedVolumeMl,
            count: count,
            abv: selectedABV,
            density: alcoholUnit.density(for: guideline)
        )
    }

    /// Re-resolve the selected ml to the nearest native option for the active
    /// unit system, so a unit switch keeps the selection stable instead of leaving
    /// it on an off-region row.
    func resolveVolumeForUnit() {
        if let nearest = DrinkMassCalculator.nearestVolumeMl(to: volumeMl, in: volumeOptions) {
            volumeMl = nearest
        }
    }

    // Rebuild the cached ABV list for the user's precision and snap the selection to
    // an exact member. No-op on the common 0.5 % path (already built in init).
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
        dismissSheet?()
    }
}
