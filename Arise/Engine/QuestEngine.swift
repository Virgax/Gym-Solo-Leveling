import Foundation

/// Generates the day's quests and measures progress against a snapshot.
/// Targets scale gently with level. See SYSTEM_DESIGN.md §4.
enum QuestEngine {

    static func dailyQuests(for snapshot: HealthSnapshot, level: Int, dayKey: String) -> [Quest] {
        let tier = Double(min(level, 60))

        let strengthTarget = 20 + tier * 0.5          // 20 → 50 min
        let stepTarget = 6000 + tier * 100            // 6k → 12k
        let energyTarget = 350 + tier * 5             // 350 → 650 kcal
        let sleepTarget = 7.0

        return [
            Quest(id: "\(dayKey).strength",
                  title: "Train the Body",
                  metric: .strengthMinutes,
                  target: strengthTarget,
                  progress: snapshot.strengthMinutesToday,
                  unit: "min", xpReward: 60, isMandatory: true),
            Quest(id: "\(dayKey).steps",
                  title: "Keep Moving",
                  metric: .steps,
                  target: stepTarget,
                  progress: snapshot.stepsToday,
                  unit: "steps", xpReward: 40, isMandatory: true),
            Quest(id: "\(dayKey).burn",
                  title: "Burn",
                  metric: .activeEnergy,
                  target: energyTarget,
                  progress: snapshot.activeEnergyToday,
                  unit: "kcal", xpReward: 40, isMandatory: false),
            Quest(id: "\(dayKey).recover",
                  title: "Recover",
                  metric: .sleepHours,
                  target: sleepTarget,
                  progress: snapshot.sleepHoursLastNight ?? 0,
                  unit: "h", xpReward: 30, isMandatory: false),
        ]
    }
}
