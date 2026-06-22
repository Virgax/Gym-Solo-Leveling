import Foundation

/// The heart of the System: converts a `HealthSnapshot` into Stats and daily XP.
/// All tuning constants live here. See SYSTEM_DESIGN.md §2–§3.
enum SystemFormula {

    // MARK: - Daily XP

    /// XP earned from *today's* continuous metrics. Idempotent: depends only on
    /// the snapshot, so re-running replaces the day's value, never stacks.
    static func dailyMetricXP(from s: HealthSnapshot) -> Int {
        var xp = 0.0
        xp += s.stepsToday / 200.0          // 10k steps ≈ 50
        xp += s.activeEnergyToday * 0.15
        xp += s.exerciseMinutesToday * 1.5
        xp += s.strengthMinutesToday * 2.0  // gym emphasis
        xp += sleepScore(hours: s.sleepHoursLastNight)
        return Int(xp.rounded())
    }

    /// 0…40 reward for a healthy night. nil/0 → 0 (untracked, no penalty here).
    static func sleepScore(hours: Double?) -> Double {
        guard let h = hours, h > 0 else { return 0 }
        switch h {
        case 7...9: return 40
        case 6..<7: return 28
        case 9..<10: return 32
        case 5..<6: return 16
        default: return 8
        }
    }

    // MARK: - Stats

    static func stats(from s: HealthSnapshot, level: Int) -> [Stat] {
        let trainedBonus = Double(level * 2)
        return StatKind.allCases.map { kind in
            let c = condition(for: kind, s: s)
            let value = Int((c * 100 + trainedBonus).rounded())
            return Stat(kind: kind, value: value, condition: c)
        }
    }

    /// 0…1 "current condition" for a stat, normalized against strong targets.
    private static func condition(for kind: StatKind, s: HealthSnapshot) -> Double {
        switch kind {
        case .strength:
            // Strength-work minutes + lean-mass quality (Eufy).
            let work = norm(s.avgStrengthMinutes, target: 35)
            let lean = leanQuality(s)
            return blend(work, 0.7, lean, 0.3)

        case .agility:
            let steps = norm(s.avgSteps, target: 11000)
            let dist = norm(s.avgDistanceMeters, target: 7000)
            let cardio = norm(s.avgCardioMinutes, target: 30)
            return blend3(steps, 0.45, dist, 0.25, cardio, 0.30)

        case .vitality:
            let rhr = inverseNorm(s.restingHeartRate, best: 45, worst: 85)
            let hrv = norm(s.hrvSDNN, target: 90)
            let vo2 = norm(s.vo2Max, target: 50)
            return blend3(rhr, 0.4, hrv, 0.35, vo2, 0.25)

        case .endurance:
            let ex = norm(s.avgExerciseMinutes, target: 60)
            let burn = norm(s.avgActiveEnergy, target: 750)
            let streak = norm(Double(s.workoutStreakDays), target: 14)
            return blend3(ex, 0.45, burn, 0.30, streak, 0.25)

        case .sense:
            let sleep = sleepCondition(s.avgSleepHours)
            // SpO₂ is higher-is-better: map 92%→0, 99%→1.
            let spo2 = rampNorm(s.spo2.map { $0 * 100 }, low: 92, high: 99)
            let hrv = norm(s.hrvSDNN, target: 90)
            return blend3(sleep, 0.55, spo2, 0.2, hrv, 0.25)
        }
    }

    /// Body-composition modifier from the Eufy scale, surfaced separately in UI.
    /// Returns a multiplier ~0.9…1.1 centered on a healthy body-fat band.
    static func conditionModifier(from s: HealthSnapshot) -> Double {
        guard let bf = s.bodyFatPercentage else { return 1.0 }
        // Reward the 10–20% band, taper outside it.
        let pct = bf * 100
        switch pct {
        case 10...20: return 1.1
        case 8..<10, 20..<24: return 1.0
        case 24..<30: return 0.95
        default: return 0.9
        }
    }

    // MARK: - Normalization helpers

    private static func norm(_ value: Double?, target: Double) -> Double {
        guard let v = value, target > 0 else { return 0 }
        return min(1, max(0, v / target))
    }

    /// Lower-is-better metrics (resting HR). `best`→1, `worst`→0.
    private static func inverseNorm(_ value: Double?, best: Double, worst: Double) -> Double {
        guard let v = value else { return 0 }
        if v <= best { return 1 }
        if v >= worst { return 0 }
        return (worst - v) / (worst - best)
    }

    /// Higher-is-better ramp: `low`→0, `high`→1, clamped.
    private static func rampNorm(_ value: Double?, low: Double, high: Double) -> Double {
        guard let v = value, high > low else { return 0 }
        return min(1, max(0, (v - low) / (high - low)))
    }

    private static func sleepCondition(_ hours: Double) -> Double {
        guard hours > 0 else { return 0 }
        switch hours {
        case 7...9: return 1.0
        case 6..<7: return 0.75
        case 9..<10: return 0.85
        case 5..<6: return 0.45
        default: return 0.2
        }
    }

    private static func leanQuality(_ s: HealthSnapshot) -> Double {
        guard let lean = s.leanBodyMassKg, let mass = s.bodyMassKg, mass > 0 else { return 0.5 }
        return min(1, max(0, (lean / mass - 0.6) / 0.3)) // ~60%→0, ~90%→1
    }

    private static func blend(_ a: Double, _ wa: Double, _ b: Double, _ wb: Double) -> Double {
        (a * wa + b * wb) / (wa + wb)
    }
    private static func blend3(_ a: Double, _ wa: Double, _ b: Double, _ wb: Double, _ c: Double, _ wc: Double) -> Double {
        (a * wa + b * wb + c * wc) / (wa + wb + wc)
    }
}
