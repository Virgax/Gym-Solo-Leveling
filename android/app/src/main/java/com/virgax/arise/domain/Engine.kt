package com.virgax.arise.domain

import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** XP ⇄ Level. */
object LevelingEngine {
    fun xpToNext(fromLevel: Int): Int = 100 + max(0, fromLevel) * 40

    fun cumulativeXP(toReach: Int): Int {
        if (toReach <= 1) return 0
        var total = 0
        for (l in 1 until toReach) total += xpToNext(l)
        return total
    }

    fun level(forTotalXP: Int): Int {
        var level = 1
        while (forTotalXP >= cumulativeXP(level + 1)) level++
        return level
    }

    /** (xpIntoLevel, xpForThisLevel). */
    fun progress(forTotalXP: Int): Pair<Int, Int> {
        val lvl = level(forTotalXP)
        return Pair(forTotalXP - cumulativeXP(lvl), xpToNext(lvl))
    }
}

/** Body-composition math (standard formulas). */
object HealthMath {
    fun bmi(weightKg: Double, heightCm: Double): Double {
        if (heightCm <= 0) return 0.0
        val m = heightCm / 100.0
        return weightKg / (m * m)
    }

    fun bmiCategory(bmi: Double): String = when {
        bmi < 18.5 -> "Underweight"
        bmi < 25 -> "Normal"
        bmi < 30 -> "Overweight"
        else -> "Obese"
    }

    fun bmr(weightKg: Double, heightCm: Double, age: Int, sex: Sex): Double {
        val base = 10 * weightKg + 6.25 * heightCm - 5 * age
        return when (sex) {
            Sex.MALE -> base + 5
            Sex.FEMALE -> base - 161
            Sex.OTHER -> base - 78
        }
    }

    fun tdee(bmr: Double, activity: ActivityLevel): Double = bmr * activity.factor

    fun calorieTarget(tdee: Double, goal: Goal): Int = when (goal) {
        Goal.LOSE -> (tdee - 500).roundToInt()
        Goal.MAINTAIN -> tdee.roundToInt()
        Goal.GAIN -> (tdee + 350).roundToInt()
    }

    fun proteinTargetG(weightKg: Double, goal: Goal): Int =
        (weightKg * if (goal == Goal.LOSE) 2.0 else 1.8).roundToInt()

    fun waterTargetMl(weightKg: Double): Int = min(4000.0, max(2000.0, weightKg * 35)).roundToInt()

    fun caffeineLimitMg(weightKg: Double): Int = min(400.0, weightKg * 6).roundToInt()
}

/** Converts a snapshot into stats and daily XP. */
object SystemFormula {

    fun dailyMetricXP(s: HealthSnapshot): Int {
        var xp = 0.0
        xp += s.stepsToday / 200.0
        xp += s.activeEnergyToday * 0.15
        xp += s.exerciseMinutesToday * 1.5
        xp += s.strengthMinutesToday * 2.0
        xp += sleepScore(s.sleepHoursLastNight)
        return xp.roundToInt()
    }

    fun nutritionXP(log: DailyLog, targets: NutritionTargets): Int {
        var xp = 0.0
        xp += min(1.0, log.waterMl.toDouble() / max(1, targets.waterMl)) * 20
        xp += min(1.0, log.totalProteinG / max(1, targets.proteinG)) * 25
        xp += log.mealsLogged * 4.0
        return xp.roundToInt()
    }

    fun sleepScore(hours: Double?): Double {
        val h = hours ?: return 0.0
        if (h <= 0) return 0.0
        return when {
            h in 7.0..9.0 -> 40.0
            h in 6.0..7.0 -> 28.0
            h in 9.0..10.0 -> 32.0
            h in 5.0..6.0 -> 16.0
            else -> 8.0
        }
    }

    fun stats(s: HealthSnapshot, level: Int): List<Stat> {
        val trainedBonus = (level * 2).toDouble()
        return StatKind.entries.map { kind ->
            val c = condition(kind, s)
            Stat(kind, (c * 100 + trainedBonus).roundToInt(), c)
        }
    }

    fun conditionModifier(s: HealthSnapshot): Double {
        val bf = s.bodyFatPercentage ?: return 1.0
        val pct = bf * 100
        return when {
            pct in 10.0..20.0 -> 1.1
            pct in 8.0..10.0 || pct in 20.0..24.0 -> 1.0
            pct in 24.0..30.0 -> 0.95
            else -> 0.9
        }
    }

    private fun condition(kind: StatKind, s: HealthSnapshot): Double = when (kind) {
        StatKind.STRENGTH -> blend(norm(s.avgStrengthMinutes, 35.0), 0.7, leanQuality(s), 0.3)
        StatKind.AGILITY -> blend3(
            norm(s.avgSteps, 11000.0), 0.45,
            norm(s.avgDistanceMeters, 7000.0), 0.25,
            norm(s.avgCardioMinutes, 30.0), 0.30,
        )
        StatKind.VITALITY -> blend3(
            inverseNorm(s.restingHeartRate, 45.0, 85.0), 0.4,
            norm(s.hrvSDNN, 90.0), 0.35,
            norm(s.vo2Max, 50.0), 0.25,
        )
        StatKind.ENDURANCE -> blend3(
            norm(s.avgExerciseMinutes, 60.0), 0.45,
            norm(s.avgActiveEnergy, 750.0), 0.30,
            norm(s.workoutStreakDays.toDouble(), 14.0), 0.25,
        )
        StatKind.SENSE -> blend3(
            sleepCondition(s.avgSleepHours), 0.55,
            rampNorm(s.spo2?.times(100), 92.0, 99.0), 0.2,
            norm(s.hrvSDNN, 90.0), 0.25,
        )
    }

    private fun norm(value: Double?, target: Double): Double {
        if (value == null || target <= 0) return 0.0
        return min(1.0, max(0.0, value / target))
    }

    private fun inverseNorm(value: Double?, best: Double, worst: Double): Double {
        val v = value ?: return 0.0
        if (v <= best) return 1.0
        if (v >= worst) return 0.0
        return (worst - v) / (worst - best)
    }

    private fun rampNorm(value: Double?, low: Double, high: Double): Double {
        if (value == null || high <= low) return 0.0
        return min(1.0, max(0.0, (value - low) / (high - low)))
    }

    private fun sleepCondition(hours: Double): Double {
        if (hours <= 0) return 0.0
        return when {
            hours in 7.0..9.0 -> 1.0
            hours in 6.0..7.0 -> 0.75
            hours in 9.0..10.0 -> 0.85
            hours in 5.0..6.0 -> 0.45
            else -> 0.2
        }
    }

    private fun leanQuality(s: HealthSnapshot): Double {
        val lean = s.leanBodyMassKg ?: return 0.5
        val mass = s.bodyMassKg ?: return 0.5
        if (mass <= 0) return 0.5
        return min(1.0, max(0.0, (lean / mass - 0.6) / 0.3))
    }

    private fun blend(a: Double, wa: Double, b: Double, wb: Double) = (a * wa + b * wb) / (wa + wb)
    private fun blend3(a: Double, wa: Double, b: Double, wb: Double, c: Double, wc: Double) =
        (a * wa + b * wb + c * wc) / (wa + wb + wc)
}

// ---- Quests ----

enum class QuestCategory { TRAINING, RECOVERY, FUEL }
enum class QuestMetric { STRENGTH_MINUTES, STEPS, ACTIVE_ENERGY, SLEEP_HOURS, WATER, PROTEIN, MEALS_LOGGED }

data class Quest(
    val id: String,
    val title: String,
    val metric: QuestMetric,
    val category: QuestCategory,
    val target: Double,
    val progress: Double,
    val unit: String,
    val xpReward: Int,
    val mandatory: Boolean,
) {
    val fraction: Double get() = if (target <= 0) 1.0 else min(1.0, progress / target)
    val complete: Boolean get() = progress >= target
    val progressText: String get() = "${progress.roundToInt()} / ${target.roundToInt()} $unit"
}

object QuestEngine {
    fun dailyQuests(
        s: HealthSnapshot,
        intake: IntakeSnapshot,
        targets: NutritionTargets,
        level: Int,
        dayKey: String,
    ): List<Quest> {
        val tier = min(level, 60).toDouble()
        return listOf(
            Quest("$dayKey.strength", "Train the Body", QuestMetric.STRENGTH_MINUTES, QuestCategory.TRAINING,
                20 + tier * 0.5, s.strengthMinutesToday, "min", 60, true),
            Quest("$dayKey.steps", "Keep Moving", QuestMetric.STEPS, QuestCategory.TRAINING,
                6000 + tier * 100, s.stepsToday, "steps", 40, true),
            Quest("$dayKey.burn", "Burn", QuestMetric.ACTIVE_ENERGY, QuestCategory.TRAINING,
                350 + tier * 5, s.activeEnergyToday, "kcal", 40, false),
            Quest("$dayKey.hydrate", "Hydrate", QuestMetric.WATER, QuestCategory.FUEL,
                targets.waterMl.toDouble(), intake.waterMl.toDouble(), "mL", 35, true),
            Quest("$dayKey.protein", "Hit Protein", QuestMetric.PROTEIN, QuestCategory.FUEL,
                targets.proteinG.toDouble(), intake.totalProteinG, "g", 45, false),
            Quest("$dayKey.meals", "Fuel the Machine", QuestMetric.MEALS_LOGGED, QuestCategory.FUEL,
                3.0, intake.mealsLogged.toDouble(), "meals", 30, false),
            Quest("$dayKey.recover", "Recover", QuestMetric.SLEEP_HOURS, QuestCategory.RECOVERY,
                7.0, s.sleepHoursLastNight ?: 0.0, "h", 30, false),
        )
    }
}

object StreakEngine {
    fun streakBonus(streak: Int): Int = min(100, streak * 10)
}
