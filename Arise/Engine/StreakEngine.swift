import Foundation

/// Pure streak & penalty logic, Solo-Leveling style. A day is "cleared" when
/// all mandatory quests were completed. Miss a day → the streak breaks and the
/// next day enters the **Penalty Zone** until you redeem it.
enum StreakEngine {

    /// Consecutive cleared days ending today (today may still be in progress).
    static func currentStreak(clearedDays: Set<String>, today: Date = .now) -> Int {
        let cal = Calendar.current
        var cursor = cal.startOfDay(for: today)
        // Don't break the streak just because today isn't finished yet.
        if !clearedDays.contains(DayKey.string(for: cursor)) {
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        var streak = 0
        while clearedDays.contains(DayKey.string(for: cursor)) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }

    /// True when *yesterday* existed (the Hunter had the app) but wasn't cleared
    /// and today hasn't been redeemed yet.
    static func penaltyActive(clearedDays: Set<String>, createdAt: Date, today: Date = .now) -> Bool {
        let cal = Calendar.current
        let startToday = cal.startOfDay(for: today)
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: startToday) else { return false }
        // Only penalize if the account already existed yesterday.
        guard cal.startOfDay(for: createdAt) <= yesterday else { return false }
        let yKey = DayKey.string(for: yesterday)
        return !clearedDays.contains(yKey)
    }

    /// Streak completion bonus XP awarded when a day is freshly cleared.
    static func streakBonus(forStreak streak: Int) -> Int {
        min(100, streak * 10)
    }
}
