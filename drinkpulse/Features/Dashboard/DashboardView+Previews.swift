import SwiftUI
import SwiftData

#Preview("With data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    let ctx = container.mainContext
    let cal = Calendar.current
    let now = Date.now

    ctx.insert(ConsumptionEvent(consumptionDate: now, volumeMl: 568, abv: 0.05,
                                category: .beer, icon: "🍺"))
    ctx.insert(ConsumptionEvent(consumptionDate: now.addingTimeInterval(-3600), volumeMl: 175, abv: 0.135,
                                category: .wine, icon: "🍷", price: 8.50))

    let minus2 = cal.date(byAdding: .day, value: -2, to: now)!
    ctx.insert(ConsumptionEvent(consumptionDate: minus2, volumeMl: 330, abv: 0.05,
                                category: .beer, icon: "🍺", price: 4.00))
    let minus4 = cal.date(byAdding: .day, value: -4, to: now)!
    ctx.insert(ConsumptionEvent(consumptionDate: minus4, volumeMl: 250, abv: 0.12,
                                category: .wine, icon: "🍷"))

    ctx.insert(UserProfile.preview)
    return NavigationStack { DashboardView() }
        .modelContainer(container)
}

#Preview("Empty") {
    NavigationStack { DashboardView() }
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}

#Preview("Over limit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    let ctx = container.mainContext
    ctx.insert(ConsumptionEvent(consumptionDate: .now, volumeMl: 1562, abv: 0.10,
                                category: .spirits, icon: "🥃"))
    ctx.insert(UserProfile.preview)
    return NavigationStack { DashboardView() }
        .modelContainer(container)
}

#Preview("Over limit, accessibility 5") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    let ctx = container.mainContext
    ctx.insert(ConsumptionEvent(consumptionDate: .now, volumeMl: 1562, abv: 0.10,
                                category: .spirits, icon: "🥃"))
    ctx.insert(UserProfile.preview)
    return NavigationStack { DashboardView() }
        .modelContainer(container)
        .dynamicTypeSize(.accessibility5)
}

#Preview("With data · Dark") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(ConsumptionEvent(consumptionDate: .now, volumeMl: 568, abv: 0.05,
                                                  category: .beer, icon: "🍺"))
    container.mainContext.insert(UserProfile.preview)
    return NavigationStack { DashboardView() }
        .modelContainer(container)
        .preferredColorScheme(.dark)
}

/// UK guideline: no daily limit, so the hero shows the daily average and the week chart draws
/// its rule at weekly / 7, captioned "Daily average" (plan 0046, Review focus 2; review fix).
#Preview("Daily average profile") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    container.mainContext.insert(ConsumptionEvent(consumptionDate: .now, volumeMl: 500, abv: 0.05,
                                                  category: .beer, icon: "🍺"))
    container.mainContext.insert(UserProfile(guidelineChoice: .uk))
    return NavigationStack { DashboardView() }
        .modelContainer(container)
}

/// Over the weekly limit, nothing today: alert card shown, hero Within Limit (Review focus 1).
#Preview("Over weekly limit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    let cal = Calendar.current
    for daysAgo in [1, 2] {
        let day = cal.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        container.mainContext.insert(ConsumptionEvent(consumptionDate: day, volumeMl: 500, abv: 0.05,
                                                      quantity: 4, category: .beer, icon: "🍺"))
    }
    container.mainContext.insert(UserProfile.preview)
    return NavigationStack { DashboardView() }
        .modelContainer(container)
}
