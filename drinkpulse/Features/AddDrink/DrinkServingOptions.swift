import Foundation

/// The values the serving wheels offer, shared by Add Drink step 2 and Edit Drink (plan 0047).
enum DrinkServingOptions {
    /// The preset's servings for `unitSystem` (all of them if the unit system has none; the
    /// fine-grained custom list for `.custom`). A `keeping` volume that is not one of them is
    /// added as "Current", so a stored or recent volume is shown as itself and never snapped.
    static func volumeOptions(
        for preset: DrinkTypePreset,
        in unitSystem: UnitSystem,
        keeping volumeMl: Double?
    ) -> [DrinkTypePreset.VolumeOption] {
        var options = preset.category == .custom
            ? DrinkTypePreset.customVolumes(for: unitSystem)
            : preset.volumes(for: unitSystem)
        if options.isEmpty { options = preset.volumes }
        guard let volumeMl, !options.contains(where: { $0.volumeMl == volumeMl }) else {
            return options
        }
        options.append(.init(
            descriptor: String(localized: "editDrink.currentServing"),
            volumeMl: volumeMl,
            regions: [unitSystem]
        ))
        return options.sorted { $0.volumeMl < $1.volumeMl }
    }

    /// The preset's strength range on the user's precision grid (`stepPermille`).
    static func abvValues(for preset: DrinkTypePreset, stepPermille: Int) -> [Double] {
        DrinkTypePreset.abvRange(
            from: Int((preset.abvMin * 1000).rounded()),
            through: Int((preset.abvMax * 1000).rounded()),
            step: stepPermille
        )
    }

    /// `abv` on the preset's strength grid at the user's precision. Snaps from the given value
    /// (a stored or Recent ABV, or a preset default), never from an already-snapped one.
    static func strength(_ abv: Double, for preset: DrinkTypePreset, stepPermille: Int) -> Double {
        nearest(abv, in: abvValues(for: preset, stepPermille: stepPermille))
    }

    /// The grid value closest to `abv`, or `abv` itself when the grid is empty.
    static func nearest(_ abv: Double, in values: [Double]) -> Double {
        values.min(by: { abs($0 - abv) < abs($1 - abv) }) ?? abv
    }
}
