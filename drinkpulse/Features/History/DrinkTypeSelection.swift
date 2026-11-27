import Foundation

/// How a tap in Edit Drink's type list changes the event's category (plan 0047, D0047-2).
enum DrinkTypeSelection {
    /// The new category, or nil when the tapped row already stands for `current` (so a Cognac
    /// event that taps Brandy & Cognac keeps `.cognac` and its serving).
    static func apply(_ tapped: DrinkCategory, to current: DrinkCategory) -> DrinkCategory? {
        DrinkTypeGroup.pickerCategory(for: current) == tapped ? nil : tapped
    }

    /// Whether `row` is the list row that represents `current` (checkmark).
    static func isSelected(_ row: DrinkCategory, current: DrinkCategory) -> Bool {
        DrinkTypeGroup.pickerCategory(for: current) == row
    }
}
