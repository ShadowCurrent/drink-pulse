import Foundation
import Testing
@testable import drinkpulse

@MainActor
struct HealthStepTests {

    @Test func disableWeeklySummary_callsServiceCancel() async {
        let fake = FakeNotificationCenter()
        let service = WeeklySummaryService(center: fake, defaults: UserDefaults(suiteName: "test.healthStep.\(UUID().uuidString)")!)
        let step = HealthStep(onDone: {}, weeklySummaryService: service)

        await step.disableWeeklySummary()

        #expect(fake.removedBatches.last == [WeeklySummaryService.weeklySummaryIdentifier])
    }
}
