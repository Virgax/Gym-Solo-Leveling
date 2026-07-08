import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, morningSnack, lunch, afternoonSnack, dinner
    var id: String { rawValue }

    var label: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .morningSnack: return "Morning Snack"
        case .lunch: return "Lunch"
        case .afternoonSnack: return "Afternoon Snack"
        case .dinner: return "Dinner"
        }
    }
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .morningSnack: return "cup.and.saucer.fill"
        case .lunch: return "fork.knife"
        case .afternoonSnack: return "carrot.fill"
        case .dinner: return "moon.stars.fill"
        }
    }
    /// Suggested time of day, for the meal schedule.
    var suggestedHour: Int {
        switch self {
        case .breakfast: return 8
        case .morningSnack: return 11
        case .lunch: return 14
        case .afternoonSnack: return 17
        case .dinner: return 21
        }
    }
}

struct MealEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var type: MealType
    var name: String
    var calories: Int
    var proteinG: Double?
    var loggedAt: Date = .now
}

/// One day of intake + training log. The per-day source of truth for fuel,
/// hydration and completed Gates (routines). Keyed by yyyy-MM-dd.
struct DailyLog: Codable {
    var dayKey: String
    var waterMl: Int = 0
    var caffeineMg: Int = 0
    var meals: [MealEntry] = []

    /// Minutes of strength work contributed by completed Gates (added on top of
    /// HealthKit data so logged routines count toward stats & quests).
    var gateMinutes: Int = 0
    /// Routine ids already rewarded today (one bonus per routine per day).
    var completedGateIDs: [String] = []

    var totalCalories: Int { meals.reduce(0) { $0 + $1.calories } }
    var totalProteinG: Double { meals.reduce(0) { $0 + ($1.proteinG ?? 0) } }
    var mealsLogged: Int { Set(meals.map { $0.type }).count }

    func meals(of type: MealType) -> [MealEntry] { meals.filter { $0.type == type } }
    func calories(of type: MealType) -> Int { meals(of: type).reduce(0) { $0 + $1.calories } }
}

/// Lightweight view the quest/XP engine reads (decoupled from storage).
struct IntakeSnapshot {
    var waterMl: Int
    var caffeineMg: Int
    var totalCalories: Int
    var totalProteinG: Double
    var mealsLogged: Int

    init(_ log: DailyLog) {
        waterMl = log.waterMl
        caffeineMg = log.caffeineMg
        totalCalories = log.totalCalories
        totalProteinG = log.totalProteinG
        mealsLogged = log.mealsLogged
    }
}
