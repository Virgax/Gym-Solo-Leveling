import Foundation

/// Persisted progression. Source of truth is the XP ledgers; Level and Rank are
/// always *derived* so they can never drift out of sync. See SYSTEM_DESIGN.md §3.
struct HunterProfile: Codable {
    var name: String = "Hunter"
    var createdAt: Date = .now

    /// Day (yyyy-MM-dd) → XP from continuous metrics. Recomputed/replaced on
    /// each sync so re-reading a day never double-counts.
    var metricLedger: [String: Int] = [:]

    /// Day (yyyy-MM-dd) → sticky bonus XP from completed quests. Only grows.
    var questLedger: [String: Int] = [:]

    /// Quest ids already awarded, so a quest pays out once.
    var awardedQuestIDs: Set<String> = []

    /// Last level the user has actually *seen*, for level-up detection.
    var lastSeenLevel: Int = 1
}

extension HunterProfile {
    var totalXP: Int {
        metricLedger.values.reduce(0, +) + questLedger.values.reduce(0, +)
    }
    var level: Int { LevelingEngine.level(forTotalXP: totalXP) }
    var rank: Rank { Rank.forLevel(level) }
}
