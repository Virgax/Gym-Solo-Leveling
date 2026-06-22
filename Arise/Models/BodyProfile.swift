import Foundation

/// Pure body-composition math used during onboarding and for daily targets.
/// All formulas are standard and documented inline so the UI can explain them.
enum HealthMath {

    /// Body Mass Index = kg / m².
    static func bmi(weightKg: Double, heightCm: Double) -> Double {
        guard heightCm > 0 else { return 0 }
        let m = heightCm / 100
        return weightKg / (m * m)
    }

    enum BMICategory: String {
        case underweight = "Underweight"
        case normal = "Normal"
        case overweight = "Overweight"
        case obese = "Obese"

        static func from(_ bmi: Double) -> BMICategory {
            switch bmi {
            case ..<18.5: return .underweight
            case 18.5..<25: return .normal
            case 25..<30: return .overweight
            default: return .obese
            }
        }
    }

    /// Basal Metabolic Rate via Mifflin–St Jeor.
    static func bmr(weightKg: Double, heightCm: Double, age: Int, sex: Sex) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        switch sex {
        case .male:   return base + 5
        case .female: return base - 161
        case .other:  return base - 78   // average of the two constants
        }
    }

    /// Total Daily Energy Expenditure = BMR × activity factor.
    static func tdee(bmr: Double, activity: ActivityLevel) -> Double {
        bmr * activity.factor
    }

    /// Daily calorie target shifted by goal.
    static func calorieTarget(tdee: Double, goal: Goal) -> Int {
        switch goal {
        case .lose:     return Int((tdee - 500).rounded())
        case .maintain: return Int(tdee.rounded())
        case .gain:     return Int((tdee + 350).rounded())
        }
    }

    /// Protein target (g/day). Higher when cutting to preserve muscle.
    static func proteinTargetG(weightKg: Double, goal: Goal) -> Int {
        let perKg = goal == .lose ? 2.0 : 1.8
        return Int((weightKg * perKg).rounded())
    }

    /// Water target (mL/day) ≈ 35 mL/kg, clamped to a sane band.
    static func waterTargetMl(weightKg: Double) -> Int {
        Int(min(4000, max(2000, weightKg * 35)).rounded())
    }

    /// Sensible daily caffeine ceiling (FDA): 400 mg, capped at 6 mg/kg.
    static func caffeineLimitMg(weightKg: Double) -> Int {
        Int(min(400, weightKg * 6).rounded())
    }
}

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male, female, other
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary, light, moderate, active, athlete
    var id: String { rawValue }
    var factor: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .athlete: return 1.9
        }
    }
    var label: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Lightly active"
        case .moderate: return "Moderately active"
        case .active: return "Very active"
        case .athlete: return "Athlete"
        }
    }
    var detail: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .light: return "1–3 days / week"
        case .moderate: return "3–5 days / week"
        case .active: return "6–7 days / week"
        case .athlete: return "Hard daily training"
        }
    }
}

enum Goal: String, Codable, CaseIterable, Identifiable {
    case lose, maintain, gain
    var id: String { rawValue }
    var label: String {
        switch self {
        case .lose: return "Lose fat"
        case .maintain: return "Maintain"
        case .gain: return "Build muscle"
        }
    }
    var icon: String {
        switch self {
        case .lose: return "flame.fill"
        case .maintain: return "equal.circle.fill"
        case .gain: return "bolt.fill"
        }
    }
}

/// Everything the user enters/derives at setup. Source of truth for targets.
struct BodyProfile: Codable {
    var sex: Sex = .male
    var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: .now) ?? .now
    var heightCm: Double = 175
    var weightKg: Double = 75
    var activity: ActivityLevel = .moderate
    var goal: Goal = .maintain

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: .now).year ?? 25
    }
    var bmi: Double { HealthMath.bmi(weightKg: weightKg, heightCm: heightCm) }
    var bmiCategory: HealthMath.BMICategory { .from(bmi) }
    var bmr: Double { HealthMath.bmr(weightKg: weightKg, heightCm: heightCm, age: age, sex: sex) }
    var tdee: Double { HealthMath.tdee(bmr: bmr, activity: activity) }

    var targets: NutritionTargets {
        NutritionTargets(
            calories: HealthMath.calorieTarget(tdee: tdee, goal: goal),
            proteinG: HealthMath.proteinTargetG(weightKg: weightKg, goal: goal),
            waterMl: HealthMath.waterTargetMl(weightKg: weightKg),
            caffeineLimitMg: HealthMath.caffeineLimitMg(weightKg: weightKg)
        )
    }
}

struct NutritionTargets {
    var calories: Int
    var proteinG: Int
    var waterMl: Int
    var caffeineLimitMg: Int

    /// Default targets before onboarding completes.
    static let `default` = NutritionTargets(calories: 2200, proteinG: 120, waterMl: 2500, caffeineLimitMg: 400)
}
