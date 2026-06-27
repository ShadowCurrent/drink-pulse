import Foundation

@Observable @MainActor final class InsightsViewModel {
    var events: [ConsumptionEvent] = [] {
        didSet { rebuildGramsByDay() }
    }
    // Changing the display unit changes the aggregation density, so rebuild the cache.
    var profile: UserProfile? = nil {
        didSet { rebuildGramsByDay() }
    }
    var now: Date = .now
    var period: InsightsPeriod = .week

    /// Volume→mass density for the active display unit. See plan-0025 / DashboardViewModel.
    var modeDensity: Double {
        (profile?.alcoholUnit ?? .standardDrinks).density(for: profile?.guidelineChoice ?? .who)
    }

    // Mode-mass grams bucketed by start-of-day, rebuilt whenever `events` or `profile`
    // changes. Lets `gramsForDay` be O(1) instead of scanning all events per day —
    // every per-day aggregate (totals, series, weekday, streaks) reads from this,
    // so a 365-day scope is O(events + days) rather than O(days × events).
    @ObservationIgnored private var gramsByDay: [Date: Double] = [:]

    // Cached span start, rebuilt with `gramsByDay`. `activeDateRange` (all-time)
    // reads it, and that range is derived on every `activeDays` access, so an
    // uncached O(events) scan ran many times per render.
    //
    // NOT `@ObservationIgnored`: the navigator's prev-button enablement reads this
    // (via `minAllowedOffset`). Events load asynchronously, so the value must be a
    // tracked dependency or the button stays stale until an unrelated re-render
    // (e.g. switching period) — that was a real bug. It is only ever written from
    // `rebuildGramsByDay` (an `events`/`profile` didSet), never during a body pass,
    // so observing it cannot cause a "mutating state during view update" loop.
    private var cachedOldestEventDate: Date?

    private func rebuildGramsByDay() {
        let density = modeDensity
        var map: [Date: Double] = [:]
        map.reserveCapacity(events.count)
        var oldest = Date.distantFuture
        for e in events {
            map[cal.startOfDay(for: e.timestamp), default: 0] += e.alcoholGrams(density: density)
            if e.timestamp < oldest { oldest = e.timestamp }
        }
        gramsByDay = map
        cachedOldestEventDate = events.isEmpty ? nil : oldest
        cachedDaysRange = nil
    }

    // Independent offset per scope — preserved when switching between scopes
    private(set) var weekOffset: Int = 0
    private(set) var monthOffset: Int = 0
    private(set) var yearOffset: Int = 0

    // MARK: - Navigation

    var activeOffset: Int {
        switch period {
        case .week:    return weekOffset
        case .month:   return monthOffset
        case .year:    return yearOffset
        case .allTime: return 0
        }
    }

    var isAllTime: Bool { period == .allTime }

    var isCurrentPeriod: Bool { activeOffset == 0 }

    var oldestEventDate: Date? { cachedOldestEventDate }

    var minAllowedOffset: Int {
        guard let oldest = oldestEventDate else { return 0 }
        return period.offset(for: oldest, relativeTo: now, calendar: cal)
    }

    func navigatePrev() {
        guard !isAllTime else { return }
        let next = activeOffset - 1
        guard next >= minAllowedOffset else { return }
        setOffset(next)
    }

    func navigateNext() {
        guard !isAllTime, activeOffset < 0 else { return }
        setOffset(activeOffset + 1)
    }

    func jumpToNow() {
        guard !isAllTime else { return }
        setOffset(0)
    }

    private func setOffset(_ value: Int) {
        switch period {
        case .week:    weekOffset = value
        case .month:   monthOffset = value
        case .year:    yearOffset = value
        case .allTime: break
        }
    }

    // MARK: - Calendar

    var cal: Calendar { Calendar.current }

    // MARK: - Active date range

    var activeDateRange: ClosedRange<Date> {
        if isAllTime {
            let start = oldestEventDate.map { cal.startOfDay(for: $0) } ?? cal.startOfDay(for: now)
            return start...max(start, now)
        }
        return period.dateRange(offset: activeOffset, now: now, calendar: cal)
    }

    var friendlyLabel: String {
        if isAllTime { return String(localized: "insights.nav.allTime") }
        return period.friendlyLabel(offset: activeOffset, now: now, calendar: cal)
    }

    var rangeLabel: String {
        if isAllTime {
            let style = Date.FormatStyle.dateTime.month(.abbreviated).day().year()
            let r = activeDateRange
            return "\(r.lowerBound.formatted(style)) – \(r.upperBound.formatted(style))"
        }
        return period.rangeLabel(offset: activeOffset, now: now, calendar: cal)
    }

    // MARK: - Guideline helpers

    var sex: BiologicalSex { profile?.biologicalSex ?? .male }
    var guidelineChoice: GuidelineChoice { profile?.guidelineChoice ?? .who }

    func limits(for guideline: GuidelineChoice) -> GuidelineLimits {
        guideline.effectiveLimits(weeklyGoalGrams: profile?.weeklyGoalGrams ?? 100, for: sex)
    }

    var effectiveDailyLimitGrams: Double {
        limits(for: guidelineChoice).effectiveDailyGrams
    }

    // MARK: - Data source

    static var preview: InsightsViewModel {
        let vm = InsightsViewModel()
        vm.events = InsightsDataGenerator.previewEvents()
        vm.profile = UserProfile.preview
        return vm
    }

    func gramsForDay(_ date: Date) -> Double {
        gramsByDay[cal.startOfDay(for: date)] ?? 0
    }

    // Fast path for days already normalized to start-of-day (everything from
    // `activeDays` / `cal.days(in:)` is). Skips the per-lookup `startOfDay`, which
    // dominated the per-day reduces below — thousands of Calendar calls per render.
    func gramsForNormalizedDay(_ day: Date) -> Double {
        gramsByDay[day] ?? 0
    }

    // MARK: - Period aggregates

    // Day-iteration range. Year and All Time are clamped to `now`, so the *current*
    // year reads Jan 1 → today instead of the whole calendar year (the future months
    // carry no data and only waste work). Week and month keep their full grid, which
    // is the conventional calendar view and avoids a stub chart mid-week.
    var effectiveDateRange: ClosedRange<Date> {
        let range = activeDateRange
        switch period {
        case .week, .month:
            return range
        case .year, .allTime:
            let end = min(range.upperBound, now)
            return range.lowerBound...max(range.lowerBound, end)
        }
    }

    // `cal.days(in:)` steps day-by-day with Calendar arithmetic, which is costly
    // for a long scope (all-time can be 700+ days). Almost every metric below
    // reads `activeDays`, and `@Observable` re-runs them on each body pass, so an
    // uncached version recomputed the whole list many times per render. Memoize on
    // the range itself: it is cheap to derive and changes only when the period,
    // offset, `now`, or event span changes — exactly when the day list must rebuild.
    @ObservationIgnored private var cachedDaysRange: ClosedRange<Date>?
    @ObservationIgnored private var cachedDays: [Date] = []

    var activeDays: [Date] {
        let range = effectiveDateRange
        if let key = cachedDaysRange, key == range { return cachedDays }
        let days = cal.days(in: range)
        cachedDaysRange = range
        cachedDays = days
        return days
    }

    var periodTotalGrams: Double {
        activeDays.reduce(0) { $0 + gramsForNormalizedDay($1) }
    }

    var prevPeriodTotalGrams: Double {
        // All-time has no "previous" period; the hero hides the comparison for it.
        guard !isAllTime else { return 0 }
        let prevRange = period.dateRange(offset: activeOffset - 1, now: now, calendar: cal)
        return cal.days(in: prevRange).reduce(0) { $0 + gramsForNormalizedDay($1) }
    }

    // Exact trend; the unit-conversion constant cancels in the ratio so this is the
    // same in every display unit. No rounding workaround needed now the math is clean.
    var trendFraction: Double {
        guard prevPeriodTotalGrams > 0 else { return 0 }
        return (periodTotalGrams - prevPeriodTotalGrams) / prevPeriodTotalGrams
    }

    // MARK: - Risk level

    func riskLevel(for grams: Double) -> RiskLevel {
        guard effectiveDailyLimitGrams > 0 else { return .safe }
        return RiskLevel.from(pct: grams / effectiveDailyLimitGrams)
    }

    // MARK: - Guideline comparisons

    private func effectiveDailyLimit(for guideline: GuidelineChoice) -> Double {
        limits(for: guideline).effectiveDailyGrams
    }

    var guidelineComparisons: [GuidelineComparison] {
        let consumed = periodTotalGrams
        let days = Double(activeDays.count)
        return [GuidelineChoice.who, .uk, .de].map { guideline in
            GuidelineComparison(
                guideline: guideline,
                name: guidelineShortName(guideline),
                consumedGrams: consumed,
                limitGrams: effectiveDailyLimit(for: guideline) * days
            )
        }
    }

}
