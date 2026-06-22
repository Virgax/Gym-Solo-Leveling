import Foundation
import SwiftUI

/// The app's single source of truth: onboarding, health snapshot, daily intake,
/// Gates, and progression. Sub-views observe this via @EnvironmentObject.
@MainActor
final class SystemViewModel: ObservableObject {

    enum Phase { case onboarding, loading, ready, unavailable }

    @Published var phase: Phase = .loading
    @Published var profile: HunterProfile
    @Published var snapshot = HealthSnapshot()
    @Published var todayLog: DailyLog
    @Published var stats: [Stat] = []
    @Published var quests: [Quest] = []
    @Published var conditionModifier: Double = 1.0
    @Published var usingMockData = false

    /// Body metrics read from Health to prefill the setup flow.
    @Published var bodyPrefill = BodyPrefill()

    /// Set when a refresh crosses a level boundary — the UI shows "ARISE".
    @Published var pendingLevelUp: Int?

    private let store: ProfileStore
    private let logStore: DailyLogStore
    private let source: HealthSource

    init(store: ProfileStore = ProfileStore(),
         logStore: DailyLogStore = DailyLogStore(),
         source: HealthSource? = nil) {
        self.store = store
        self.logStore = logStore
        self.profile = store.load()
        self.todayLog = logStore.log(for: DayKey.string())
        #if canImport(HealthKit)
        self.source = source ?? HealthKitSource()
        #else
        self.source = source ?? MockHealthSource()
        #endif
    }

    // MARK: Derived

    var targets: NutritionTargets { profile.bodyProfile?.targets ?? .default }
    var levelProgress: (into: Int, span: Int) {
        LevelingEngine.progress(forTotalXP: profile.totalXP)
    }
    var caffeineMg: Int { todayLog.caffeineMg }

    // MARK: Lifecycle

    func start() async {
        if !profile.onboardingComplete {
            await beginOnboarding()
        } else {
            await authorizeAndRefresh()
        }
    }

    private func beginOnboarding() async {
        phase = .loading
        if source.isAvailable { _ = await source.requestAuthorization() }
        bodyPrefill = await source.bodyPrefill()
        phase = .onboarding
    }

    func completeOnboarding(name: String, body: BodyProfile) async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        profile.name = trimmed.isEmpty ? "Hunter" : trimmed
        profile.bodyProfile = body
        profile.onboardingComplete = true
        store.save(profile)
        await authorizeAndRefresh()
    }

    private func authorizeAndRefresh() async {
        guard source.isAvailable else { await loadFromMock(); return }
        phase = .loading
        _ = await source.requestAuthorization()
        await refresh()
    }

    func refresh() async {
        phase = .loading
        var snap = await source.snapshot()
        if !snap.hasData {
            snap = .sample
            usingMockData = true
        } else {
            usingMockData = false
        }
        snapshot = snap
        rolloverDayIfNeeded()
        reduce()
        phase = .ready
    }

    private func loadFromMock() async {
        usingMockData = true
        snapshot = .sample
        rolloverDayIfNeeded()
        reduce()
        phase = .ready
    }

    // MARK: Intake & Gate logging

    func addWater(_ ml: Int) { todayLog.waterMl = max(0, todayLog.waterMl + ml); persistLog() }
    func addCaffeine(_ mg: Int) { todayLog.caffeineMg = max(0, todayLog.caffeineMg + mg); persistLog() }

    func logMeal(_ entry: MealEntry) { todayLog.meals.append(entry); persistLog() }
    func removeMeal(_ id: UUID) { todayLog.meals.removeAll { $0.id == id }; persistLog() }

    /// Mark a Gate (routine) cleared: its minutes count toward strength, and a
    /// completion bonus is paid once per routine per day.
    func completeGate(_ routine: Routine) {
        let today = DayKey.string()
        todayLog.gateMinutes += routine.estMinutes
        if !todayLog.completedGateIDs.contains(routine.id) {
            todayLog.completedGateIDs.append(routine.id)
            let gid = "\(today).gate.\(routine.id)"
            if !profile.awardedQuestIDs.contains(gid) {
                profile.awardedQuestIDs.insert(gid)
                profile.questLedger[today, default: 0] += routine.xpReward
            }
        }
        persistLog()
    }

    private func persistLog() {
        logStore.save(todayLog)
        reduce()
    }

    private func rolloverDayIfNeeded() {
        let today = DayKey.string()
        if todayLog.dayKey != today { todayLog = logStore.log(for: today) }
    }

    // MARK: Core reduction

    /// Recomputes XP, quests and stats from the current snapshot + intake.
    private func reduce() {
        let today = DayKey.string()
        let previousLevel = profile.level

        var snap = snapshot
        snap.strengthMinutesToday += Double(todayLog.gateMinutes)

        profile.metricLedger[today] =
            SystemFormula.dailyMetricXP(from: snap) +
            SystemFormula.nutritionXP(log: todayLog, targets: targets)

        let intake = IntakeSnapshot(todayLog)
        let qs = QuestEngine.dailyQuests(snapshot: snap, intake: intake, targets: targets,
                                         level: profile.level, dayKey: today)
        for q in qs where q.isComplete && !profile.awardedQuestIDs.contains(q.id) {
            profile.awardedQuestIDs.insert(q.id)
            profile.questLedger[today, default: 0] += q.xpReward
        }
        quests = qs
        stats = SystemFormula.stats(from: snap, level: profile.level)
        conditionModifier = SystemFormula.conditionModifier(from: snap)

        let newLevel = profile.level
        if newLevel > previousLevel && newLevel > profile.lastSeenLevel {
            pendingLevelUp = newLevel
        }
        store.save(profile)
    }

    // MARK: Misc

    func acknowledgeLevelUp() {
        if let lvl = pendingLevelUp { profile.lastSeenLevel = lvl }
        pendingLevelUp = nil
        store.save(profile)
    }

    func setName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        profile.name = trimmed.isEmpty ? "Hunter" : trimmed
        store.save(profile)
    }

    func updateBody(_ body: BodyProfile) {
        profile.bodyProfile = body
        store.save(profile)
        reduce()
    }

    /// Wipe everything and return to setup.
    func resetProgress() {
        store.reset()
        logStore.reset()
        profile = HunterProfile()
        todayLog = DailyLog(dayKey: DayKey.string())
        Task { await start() }
    }
}
