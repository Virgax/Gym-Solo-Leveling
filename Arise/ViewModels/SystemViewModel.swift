import Foundation
import SwiftUI

/// Drives the whole experience: pulls a health snapshot, runs it through the
/// formula, persists progression, and publishes view-ready state.
@MainActor
final class SystemViewModel: ObservableObject {

    enum Phase { case needsAuthorization, loading, ready, unavailable }

    @Published var phase: Phase = .needsAuthorization
    @Published var profile: HunterProfile
    @Published var snapshot = HealthSnapshot()
    @Published var stats: [Stat] = []
    @Published var quests: [Quest] = []
    @Published var conditionModifier: Double = 1.0
    @Published var usingMockData = false

    /// Set when a refresh crosses a level boundary — the UI shows "ARISE".
    @Published var pendingLevelUp: Int?

    private let store: ProfileStore
    private let source: HealthSource

    init(store: ProfileStore = ProfileStore(), source: HealthSource? = nil) {
        self.store = store
        self.profile = store.load()
        #if canImport(HealthKit)
        self.source = source ?? HealthKitSource()
        #else
        self.source = source ?? MockHealthSource()
        #endif
    }

    var levelProgress: (into: Int, span: Int) {
        LevelingEngine.progress(forTotalXP: profile.totalXP)
    }

    func start() async {
        guard source.isAvailable else {
            // No HealthKit (e.g. Mac/preview): fall back to mock so the System
            // is still fully explorable.
            await loadFromMock()
            return
        }
        phase = .loading
        let granted = await source.requestAuthorization()
        guard granted else {
            phase = .needsAuthorization
            return
        }
        await refresh()
    }

    func refresh() async {
        phase = .loading
        var snap = await source.snapshot()
        if !snap.hasData {
            // Authorized but nothing to read yet (fresh ring / simulator).
            snap = .sample
            usingMockData = true
        } else {
            usingMockData = false
        }
        apply(snapshot: snap)
        phase = .ready
    }

    private func loadFromMock() async {
        usingMockData = true
        apply(snapshot: .sample)
        phase = .ready
    }

    /// Pure reduction of a snapshot into persisted progression + view state.
    private func apply(snapshot snap: HealthSnapshot) {
        self.snapshot = snap
        let today = DayKey.string(for: snap.date)
        let previousLevel = profile.level

        // 1. Idempotent metric XP for today (replace, don't stack).
        profile.metricLedger[today] = SystemFormula.dailyMetricXP(from: snap)

        // 2. Quests, with sticky payouts for newly-completed ones.
        let level = profile.level
        let quests = QuestEngine.dailyQuests(for: snap, level: level, dayKey: today)
        for quest in quests where quest.isComplete && !profile.awardedQuestIDs.contains(quest.id) {
            profile.awardedQuestIDs.insert(quest.id)
            profile.questLedger[today, default: 0] += quest.xpReward
        }
        self.quests = quests

        // 3. Stats + body-composition modifier.
        self.stats = SystemFormula.stats(from: snap, level: profile.level)
        self.conditionModifier = SystemFormula.conditionModifier(from: snap)

        // 4. Level-up detection.
        let newLevel = profile.level
        if newLevel > previousLevel && newLevel > profile.lastSeenLevel {
            pendingLevelUp = newLevel
        }

        store.save(profile)
    }

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

    /// Dev helper: wipe progression.
    func resetProgress() {
        store.reset()
        profile = HunterProfile()
        Task { await refresh() }
    }
}
