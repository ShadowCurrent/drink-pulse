import Testing
@testable import drinkpulse

// MARK: - DrinkMassCalculator tests

struct DrinkDetailInputMathTests {

    // MARK: massGrams — canonical CLAUDE.md examples (hand-verified)

    @Test func massGrams_500ml_5pct_grams_density0789() {
        // .grams unit: 500 ml × 1 × 0.05 × 0.789 = 19.725 g
        let result = DrinkMassCalculator.massGrams(volumeMl: 500, count: 1, abv: 0.05, density: 0.789)
        #expect(result == 19.725)
    }

    @Test func massGrams_355ml_5pct_standardDrinks_us_density0789() {
        // .standardDrinks US/CA: density = 0.789 (mass-defined).
        // 355 ml × 1 × 0.05 × 0.789 = 14.00475 g ≈ 1 US standard drink (14 g, per NIAAA).
        let result = DrinkMassCalculator.massGrams(volumeMl: 355, count: 1, abv: 0.05, density: 0.789)
        #expect(abs(result - 14.00475) < 1e-9)
    }

    @Test func massGrams_500ml_5pct_standardDrinks_who_density08() {
        // .standardDrinks WHO/DE/AU/UK: density = 0.8 (EU/UK unit convention).
        // 500 ml × 1 × 0.05 × 0.8 = 20.0 g = exactly 2 standard drinks (10 g each).
        let result = DrinkMassCalculator.massGrams(volumeMl: 500, count: 1, abv: 0.05, density: 0.8)
        #expect(result == 20.0)
    }

    // MARK: massGrams — edge cases

    @Test func massGrams_zeroABV_returnsZero() {
        let result = DrinkMassCalculator.massGrams(volumeMl: 500, count: 1, abv: 0.0, density: 0.789)
        #expect(result == 0.0)
    }

    @Test func massGrams_zeroVolume_returnsZero() {
        let result = DrinkMassCalculator.massGrams(volumeMl: 0.0, count: 1, abv: 0.05, density: 0.789)
        #expect(result == 0.0)
    }

    @Test func massGrams_zeroCount_returnsZero() {
        let result = DrinkMassCalculator.massGrams(volumeMl: 500, count: 0, abv: 0.05, density: 0.789)
        #expect(result == 0.0)
    }

    @Test func massGrams_countScaling() {
        // 2 × 500 ml bottles at 5% with physical density = 2 × 19.725 = 39.45 g
        let single = DrinkMassCalculator.massGrams(volumeMl: 500, count: 1, abv: 0.05, density: 0.789)
        let double = DrinkMassCalculator.massGrams(volumeMl: 500, count: 2, abv: 0.05, density: 0.789)
        #expect(double == 2 * single)
        #expect(double == 39.45)
    }

    // MARK: massGrams — density branching

    @Test func massGrams_grams_density_matches_physicalDensity() {
        // .grams always uses AlcoholUnit.physicalDensityGramsPerMl (0.789)
        let density = AlcoholUnit.grams.density(for: .who)
        let result = DrinkMassCalculator.massGrams(volumeMl: 500, count: 1, abv: 0.05, density: density)
        #expect(result == 19.725)
    }

    @Test func massGrams_standardDrinks_who_uses_08_density() {
        let density = AlcoholUnit.standardDrinks.density(for: .who)
        #expect(density == 0.8)
        let result = DrinkMassCalculator.massGrams(volumeMl: 500, count: 1, abv: 0.05, density: density)
        #expect(result == 20.0)
    }

    @Test func massGrams_standardDrinks_us_uses_physical_density() {
        let density = AlcoholUnit.standardDrinks.density(for: .us)
        #expect(density == AlcoholUnit.physicalDensityGramsPerMl)
        let result = DrinkMassCalculator.massGrams(volumeMl: 355, count: 1, abv: 0.05, density: density)
        #expect(abs(result - 14.00475) < 1e-9)
    }

    // MARK: nearestVolumeMl — volume resolution

    private let sampleOptions: [DrinkTypePreset.VolumeOption] = [
        .init(descriptor: "Small",  volumeMl: 100, regions: [.metric]),
        .init(descriptor: "Medium", volumeMl: 250, regions: [.metric]),
        .init(descriptor: "Large",  volumeMl: 500, regions: [.metric]),
    ]

    @Test func nearestVolumeMl_picksClosest() {
        // Use a target where the nearest option is unambiguous (avoid equidistant ties,
        // where Swift min(by:) keeps the first occurrence).
        let unambiguous = DrinkMassCalculator.nearestVolumeMl(to: 300, in: sampleOptions)
        // |100-300|=200, |250-300|=50, |500-300|=200 → 250
        #expect(unambiguous == 250)
    }

    @Test func nearestVolumeMl_exactMatch() {
        let result = DrinkMassCalculator.nearestVolumeMl(to: 250, in: sampleOptions)
        #expect(result == 250)
    }

    @Test func nearestVolumeMl_emptyOptions_returnsNil() {
        let result = DrinkMassCalculator.nearestVolumeMl(to: 250, in: [])
        #expect(result == nil)
    }

    @Test func nearestVolumeMl_singleOption_alwaysReturnsThat() {
        let single: [DrinkTypePreset.VolumeOption] = [
            .init(descriptor: "Only", volumeMl: 330, regions: [.metric])
        ]
        #expect(DrinkMassCalculator.nearestVolumeMl(to: 0, in: single) == 330)
        #expect(DrinkMassCalculator.nearestVolumeMl(to: 9999, in: single) == 330)
    }
}
