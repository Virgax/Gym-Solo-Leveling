import Foundation

/// Generates the day's quests and measures progress against the snapshot,
/// daily intake and the Hunter's nutrition targets. Targets scale with level.
/// See SYSTEM_DESIGN.md §4.
enum QuestEngine {

    static func dailyQuests(snapshot s: HealthSnapshot,
                            intake: IntakeSnapshot,
                            targets: NutritionTargets,
                            level: Int,
                            dayKey: String) -> [Quest] {
        let tier = Double(min(level, 60))

        let strengthTarget = 20 + tier * 0.5          // 20 → 50 min
        let stepTarget = 6000 + tier * 100            // 6k → 12k
        let energyTarget = 350 + tier * 5             // 350 → 650 kcal

        return [
            // Training
            Quest(id: "\(dayKey).strength", title: "Train the Body",
                  metric: .strengthMinutes, category: .training,
                  target: strengthTarget, progress: s.strengthMinutesToday,
                  unit: "min", xpReward: 60, isMandatory: true),
            Quest(id: "\(dayKey).steps", title: "Keep Moving",
                  metric: .steps, category: .training,
                  target: stepTarget, progress: s.stepsToday,
                  unit: "steps", xpReward: 40, isMandatory: true),
            Quest(id: "\(dayKey).burn", title: "Burn",
                  metric: .activeEnergy, category: .training,
                  target: energyTarget, progress: s.activeEnergyToday,
                  unit: "kcal", xpReward: 40, isMandatory: false),

            // Fuel
            Quest(id: "\(dayKey).hydrate", title: "Hydrate",
                  metric: .water, category: .fuel,
                  target: Double(targets.waterMl), progress: Double(intake.waterMl),
                  unit: "mL", xpReward: 35, isMandatory: true),
            Quest(id: "\(dayKey).protein", title: "Hit Protein",
                  metric: .protein, category: .fuel,
                  target: Double(targets.proteinG), progress: intake.totalProteinG,
                  unit: "g", xpReward: 45, isMandatory: false),
            Quest(id: "\(dayKey).meals", title: "Fuel the Machine",
                  metric: .mealsLogged, category: .fuel,
                  target: 3, progress: Double(intake.mealsLogged),
                  unit: "meals", xpReward: 30, isMandatory: false),

            // Recovery
            Quest(id: "\(dayKey).recover", title: "Recover",
                  metric: .sleepHours, category: .recovery,
                  target: 7, progress: s.sleepHoursLastNight ?? 0,
                  unit: "h", xpReward: 30, isMandatory: false),
        ]
    }
}
