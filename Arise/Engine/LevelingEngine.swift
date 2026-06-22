import Foundation

/// Pure functions mapping XP ⇄ Level. See SYSTEM_DESIGN.md §3.
enum LevelingEngine {
    /// XP required to advance *from* `level` to `level + 1`.
    static func xpToNext(fromLevel level: Int) -> Int {
        100 + max(0, level) * 40
    }

    /// Cumulative XP required to *reach* `level` (level 1 == 0 XP).
    static func cumulativeXP(toReach level: Int) -> Int {
        guard level > 1 else { return 0 }
        return (1..<level).reduce(0) { $0 + xpToNext(fromLevel: $1) }
    }

    static func level(forTotalXP xp: Int) -> Int {
        var level = 1
        while xp >= cumulativeXP(toReach: level + 1) { level += 1 }
        return level
    }

    /// Progress within the current level, as (xpIntoLevel, xpForThisLevel).
    static func progress(forTotalXP xp: Int) -> (into: Int, span: Int) {
        let lvl = level(forTotalXP: xp)
        let base = cumulativeXP(toReach: lvl)
        return (xp - base, xpToNext(fromLevel: lvl))
    }
}
