import Testing
@testable import drinkpulse

@MainActor
struct GuidelineChoiceDisplayTests {

    // MARK: - displayName

    @Test func displayName_allCases_nonEmpty() {
        for choice in GuidelineChoice.allCases {
            #expect(!choice.displayName.isEmpty, "displayName is empty for \(choice)")
        }
    }

    @Test func displayName_allCases_distinct() {
        let names = GuidelineChoice.allCases.map(\.displayName)
        #expect(Set(names).count == names.count, "Duplicate displayName values detected")
    }

    @Test func displayName_who_matchesLocalizedKey() {
        #expect(GuidelineChoice.who.displayName == String(localized: "settings.guideline.who"))
    }

    @Test func displayName_de_matchesLocalizedKey() {
        #expect(GuidelineChoice.de.displayName == String(localized: "settings.guideline.de"))
    }

    @Test func displayName_uk_matchesLocalizedKey() {
        #expect(GuidelineChoice.uk.displayName == String(localized: "settings.guideline.uk"))
    }

    @Test func displayName_us_matchesLocalizedKey() {
        #expect(GuidelineChoice.us.displayName == String(localized: "settings.guideline.us"))
    }

    @Test func displayName_custom_matchesLocalizedKey() {
        #expect(GuidelineChoice.custom.displayName == String(localized: "settings.guideline.custom"))
    }

    // MARK: - thresholdSummary

    @Test func thresholdSummary_whoMale_includesBothThresholdValues() {
        // WHO male: daily 20 g, weekly 100 g
        let limits = GuidelineChoice.who.limits(for: .male)
        let summary = GuidelineChoice.who.thresholdSummary(for: .male)
        #expect(!summary.isEmpty)
        // Both values should appear somewhere in the formatted string
        let dailyStr = String(format: "%.0f", limits.dailyGrams)
        let weeklyStr = String(format: "%.0f", limits.weeklyGrams)
        #expect(summary.contains(dailyStr) || summary.contains(weeklyStr),
                "Summary '\(summary)' missing threshold values")
    }

    @Test func thresholdSummary_uk_usesWeeklyOnlyBranch() {
        // UK has dailyGrams == 0, so the weekly-only format string is used
        let limits = GuidelineChoice.uk.limits(for: .male)
        #expect(limits.dailyGrams == 0)
        let summary = GuidelineChoice.uk.thresholdSummary(for: .male)
        #expect(!summary.isEmpty)
    }

    @Test func thresholdSummary_custom_isNonEmpty() {
        // .custom returns sentinel zeros; thresholdSummary must not crash or return empty
        let summary = GuidelineChoice.custom.thresholdSummary(for: .male)
        #expect(!summary.isEmpty)
    }

    @Test func thresholdSummary_allCasesAndSexes_nonEmpty() {
        for choice in GuidelineChoice.allCases {
            for sex: BiologicalSex in [.male, .female] {
                let summary = choice.thresholdSummary(for: sex)
                #expect(!summary.isEmpty, "Empty summary for \(choice)/\(sex)")
            }
        }
    }
}
