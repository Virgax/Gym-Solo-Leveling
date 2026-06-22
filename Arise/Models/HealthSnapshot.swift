import Foundation

/// A source-agnostic snapshot of the metrics the System reasons about.
///
/// On iOS this is filled by `HealthKitSource` (which transparently includes
/// RingConn + Eufy data synced into Apple Health). A future
/// `HealthConnectSource` (Android / Fitbit) fills the same struct, so the game
/// engine never needs to know where a number came from.
struct HealthSnapshot {
    var date: Date = .now

    // ---- Today (for quests & today's XP) ----
    var stepsToday: Double = 0
    var activeEnergyToday: Double = 0      // kcal
    var exerciseMinutesToday: Double = 0
    var strengthMinutesToday: Double = 0
    var sleepHoursLastNight: Double?       // nil = untracked

    // ---- 30-day rolling daily averages (for stats) ----
    var avgSteps: Double = 0
    var avgActiveEnergy: Double = 0
    var avgExerciseMinutes: Double = 0
    var avgStrengthMinutes: Double = 0
    var avgCardioMinutes: Double = 0
    var avgDistanceMeters: Double = 0
    var avgSleepHours: Double = 0
    var workoutStreakDays: Int = 0

    // ---- Latest physiological readings ----
    var restingHeartRate: Double?          // bpm  (lower is better)
    var hrvSDNN: Double?                   // ms   (higher is better)
    var vo2Max: Double?                    // mL/kg/min
    var spo2: Double?                      // 0…1
    var bodyMassKg: Double?
    var bodyFatPercentage: Double?         // 0…1
    var leanBodyMassKg: Double?

    /// Whether any real data was found (vs. a brand-new empty account).
    var hasData: Bool {
        stepsToday > 0 || activeEnergyToday > 0 || avgSteps > 0 ||
        restingHeartRate != nil || sleepHoursLastNight != nil || bodyMassKg != nil
    }
}

extension HealthSnapshot {
    /// A believable mid-game snapshot for previews / simulator with no data.
    static var sample: HealthSnapshot {
        var s = HealthSnapshot()
        s.stepsToday = 8200
        s.activeEnergyToday = 540
        s.exerciseMinutesToday = 44
        s.strengthMinutesToday = 38
        s.sleepHoursLastNight = 7.4
        s.avgSteps = 9100
        s.avgActiveEnergy = 610
        s.avgExerciseMinutes = 52
        s.avgStrengthMinutes = 31
        s.avgCardioMinutes = 24
        s.avgDistanceMeters = 6400
        s.avgSleepHours = 7.1
        s.workoutStreakDays = 6
        s.restingHeartRate = 54
        s.hrvSDNN = 78
        s.vo2Max = 48
        s.spo2 = 0.97
        s.bodyMassKg = 78
        s.bodyFatPercentage = 0.16
        s.leanBodyMassKg = 65.5
        return s
    }
}
