import Foundation

/// A single daily objective issued by the System.
struct Quest: Identifiable, Hashable {
    enum Metric: String {
        case strengthMinutes, steps, activeEnergy, sleepHours
        case water, protein, mealsLogged
    }

    enum Category: String { case training, recovery, fuel }

    let id: String
    let title: String
    let metric: Metric
    let category: Category
    let target: Double
    let progress: Double
    let unit: String
    let xpReward: Int
    let isMandatory: Bool

    var fraction: Double { target <= 0 ? 1 : min(1, progress / target) }
    var isComplete: Bool { progress >= target }

    var progressText: String {
        let p = Int(progress.rounded())
        let t = Int(target.rounded())
        return "\(p) / \(t) \(unit)"
    }
}
