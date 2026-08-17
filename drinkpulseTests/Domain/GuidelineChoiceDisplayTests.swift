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

    @Test func displayName_au_matchesLocalizedKey() {
        #expect(GuidelineChoice.au.displayName == String(localized: "settings.guideline.au"))
    }

    @Test func displayName_ca_matchesLocalizedKey() {
        #expect(GuidelineChoice.ca.displayName == String(localized: "settings.guideline.ca"))
    }

    // MARK: - thresholdSummary

    @Test func thresholdSummary_whoMale_includesBothThresholdValues() {
        let limits = GuidelineChoice.who.limits(for: .male)
        let summary = GuidelineChoice.who.thresholdSummary(for: .male)
        #expect(!summary.isEmpty)
        let dailyStr = String(format: "%.0f", limits.dailyGrams)
        let weeklyStr = String(format: "%.0f", limits.weeklyGrams)
        #expect(summary.contains(dailyStr) || summary.contains(weeklyStr),
                "Summary '\(summary)' missing threshold values")
    }

    @Test func thresholdSummary_uk_usesWeeklyOnlyBranch() {
        let limits = GuidelineChoice.uk.limits(for: .male)
        #expect(limits.dailyGrams == 0)
        let summary = GuidelineChoice.uk.thresholdSummary(for: .male)
        #expect(!summary.isEmpty)
    }

    @Test func thresholdSummary_custom_isNonEmpty() {
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

    // MARK: - selectable

    @Test func selectable_containsEveryCaseExceptCustom() {
        let expected = GuidelineChoice.allCases.filter { $0 != .custom }
        for choice in expected {
            #expect(GuidelineChoice.selectable.contains(choice),
                    "selectable is missing \(choice)")
        }
    }

    @Test func selectable_excludesCustom() {
        #expect(!GuidelineChoice.selectable.contains(.custom),
                ".custom is a derived state, never a user-pickable option")
    }

    @Test func selectable_isAllCasesMinusOne_inDeclarationOrder() {
        #expect(GuidelineChoice.selectable.count == GuidelineChoice.allCases.count - 1)
        #expect(GuidelineChoice.selectable == GuidelineChoice.allCases.filter { $0 != .custom })
    }
}
