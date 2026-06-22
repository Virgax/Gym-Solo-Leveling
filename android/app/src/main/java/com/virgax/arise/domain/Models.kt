package com.virgax.arise.domain

import java.time.LocalDate
import java.time.Period

/** Hunter rank, derived purely from level. */
enum class Rank(val label: String, val minLevel: Int) {
    E("E", 1), D("D", 10), C("C", 25), B("B", 45), A("A", 70), S("S", 100), MONARCH("MONARCH", 150);

    val title: String get() = if (this == MONARCH) "Monarch" else "$label-Rank Hunter"

    companion object {
        fun forLevel(level: Int): Rank = entries.last { level >= it.minLevel }
    }
}

enum class StatKind(val abbr: String, val display: String) {
    STRENGTH("STR", "Strength"),
    AGILITY("AGI", "Agility"),
    VITALITY("VIT", "Vitality"),
    ENDURANCE("END", "Endurance"),
    SENSE("SEN", "Sense");

    val blurb: String
        get() = when (this) {
            STRENGTH -> "Resistance training & lean mass."
            AGILITY -> "Steps, distance & cardio output."
            VITALITY -> "Resting HR, HRV & VO₂max."
            ENDURANCE -> "Sustained exercise & active burn."
            SENSE -> "Sleep, SpO₂ & recovery."
        }
}

data class Stat(val kind: StatKind, val value: Int, val condition: Double)

/** Source-agnostic fitness snapshot (filled by Health Connect on Android). */
data class HealthSnapshot(
    var stepsToday: Double = 0.0,
    var activeEnergyToday: Double = 0.0,
    var exerciseMinutesToday: Double = 0.0,
    var strengthMinutesToday: Double = 0.0,
    var sleepHoursLastNight: Double? = null,
    var avgSteps: Double = 0.0,
    var avgActiveEnergy: Double = 0.0,
    var avgExerciseMinutes: Double = 0.0,
    var avgStrengthMinutes: Double = 0.0,
    var avgCardioMinutes: Double = 0.0,
    var avgDistanceMeters: Double = 0.0,
    var avgSleepHours: Double = 0.0,
    var workoutStreakDays: Int = 0,
    var restingHeartRate: Double? = null,
    var hrvSDNN: Double? = null,
    var vo2Max: Double? = null,
    var spo2: Double? = null,
    var bodyMassKg: Double? = null,
    var bodyFatPercentage: Double? = null,
    var leanBodyMassKg: Double? = null,
) {
    val hasData: Boolean
        get() = stepsToday > 0 || activeEnergyToday > 0 || avgSteps > 0 || restingHeartRate != null

    companion object {
        val sample: HealthSnapshot
            get() = HealthSnapshot(
                stepsToday = 8200.0, activeEnergyToday = 540.0, exerciseMinutesToday = 44.0,
                strengthMinutesToday = 38.0, sleepHoursLastNight = 7.4,
                avgSteps = 9100.0, avgActiveEnergy = 610.0, avgExerciseMinutes = 52.0,
                avgStrengthMinutes = 31.0, avgCardioMinutes = 24.0, avgDistanceMeters = 6400.0,
                avgSleepHours = 7.1, workoutStreakDays = 6,
                restingHeartRate = 54.0, hrvSDNN = 78.0, vo2Max = 48.0, spo2 = 0.97,
                bodyMassKg = 78.0, bodyFatPercentage = 0.16, leanBodyMassKg = 65.5,
            )
    }
}

// ---- Body & nutrition ----

enum class Sex { MALE, FEMALE, OTHER;
    val label get() = name.lowercase().replaceFirstChar { it.uppercase() }
}

enum class ActivityLevel(val factor: Double, val label: String, val detail: String) {
    SEDENTARY(1.2, "Sedentary", "Little or no exercise"),
    LIGHT(1.375, "Lightly active", "1–3 days / week"),
    MODERATE(1.55, "Moderately active", "3–5 days / week"),
    ACTIVE(1.725, "Very active", "6–7 days / week"),
    ATHLETE(1.9, "Athlete", "Hard daily training"),
}

enum class Goal(val label: String) { LOSE("Lose fat"), MAINTAIN("Maintain"), GAIN("Build muscle") }

data class NutritionTargets(
    val calories: Int,
    val proteinG: Int,
    val waterMl: Int,
    val caffeineLimitMg: Int,
) {
    companion object {
        val DEFAULT = NutritionTargets(2200, 120, 2500, 400)
    }
}

data class BodyProfile(
    val sex: Sex = Sex.MALE,
    val birthYear: Int = LocalDate.now().year - 25,
    val heightCm: Double = 175.0,
    val weightKg: Double = 75.0,
    val activity: ActivityLevel = ActivityLevel.MODERATE,
    val goal: Goal = Goal.MAINTAIN,
) {
    val age: Int get() = Period.between(LocalDate.of(birthYear, 1, 1), LocalDate.now()).years
    val bmi: Double get() = HealthMath.bmi(weightKg, heightCm)
    val bmiCategory: String get() = HealthMath.bmiCategory(bmi)
    val bmr: Double get() = HealthMath.bmr(weightKg, heightCm, age, sex)
    val tdee: Double get() = HealthMath.tdee(bmr, activity)
    val targets: NutritionTargets
        get() = NutritionTargets(
            calories = HealthMath.calorieTarget(tdee, goal),
            proteinG = HealthMath.proteinTargetG(weightKg, goal),
            waterMl = HealthMath.waterTargetMl(weightKg),
            caffeineLimitMg = HealthMath.caffeineLimitMg(weightKg),
        )
}

enum class MealType(val display: String, val suggestedHour: Int) {
    BREAKFAST("Breakfast", 8),
    MORNING_SNACK("Morning Snack", 11),
    LUNCH("Lunch", 14),
    AFTERNOON_SNACK("Afternoon Snack", 17),
    DINNER("Dinner", 21),
}

data class MealEntry(
    val id: String,
    val type: MealType,
    val name: String,
    val calories: Int,
    val proteinG: Double?,
)

data class DailyLog(
    var waterMl: Int = 0,
    var caffeineMg: Int = 0,
    val meals: MutableList<MealEntry> = mutableListOf(),
    var gateMinutes: Int = 0,
    val completedGateIds: MutableSet<String> = mutableSetOf(),
) {
    val totalCalories: Int get() = meals.sumOf { it.calories }
    val totalProteinG: Double get() = meals.sumOf { it.proteinG ?: 0.0 }
    val mealsLogged: Int get() = meals.map { it.type }.toSet().size
    fun meals(of: MealType) = meals.filter { it.type == of }
}

data class IntakeSnapshot(
    val waterMl: Int,
    val totalCalories: Int,
    val totalProteinG: Double,
    val mealsLogged: Int,
) {
    constructor(log: DailyLog) : this(log.waterMl, log.totalCalories, log.totalProteinG, log.mealsLogged)
}
