package com.virgax.arise

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import com.virgax.arise.domain.*
import kotlin.math.max

/**
 * In-memory app state for the Android build. Drives the System from a sample
 * HealthSnapshot plus the intake/Gates the user logs. (Health Connect ingestion
 * and persistence are the next milestone — see README.)
 */
class AriseViewModel : ViewModel() {

    var onboardingDone by mutableStateOf(false)
        private set
    var hunterName by mutableStateOf("Hunter")
        private set
    var body by mutableStateOf(BodyProfile())
        private set

    // Physiological data: sample until Health Connect provides the real thing.
    var snapshot by mutableStateOf(HealthSnapshot.sample)
        private set
    var healthConnected by mutableStateOf(false)
        private set

    var waterMl by mutableIntStateOf(0)
        private set
    var caffeineMg by mutableIntStateOf(0)
        private set
    val meals = mutableStateListOf<MealEntry>()
    var gateMinutes by mutableIntStateOf(0)
        private set
    val clearedGateIds = mutableStateListOf<String>()

    private val awarded = mutableSetOf<String>()
    var bonusXp by mutableIntStateOf(0)
        private set

    val targets: NutritionTargets get() = if (onboardingDone) body.targets else NutritionTargets.DEFAULT

    private fun log(): DailyLog =
        DailyLog(waterMl, caffeineMg, meals.toMutableList(), gateMinutes, clearedGateIds.toMutableSet())

    private val effectiveSnapshot: HealthSnapshot
        get() = snapshot.copy(strengthMinutesToday = snapshot.strengthMinutesToday + gateMinutes)

    val totalXp: Int
        get() = SystemFormula.dailyMetricXP(effectiveSnapshot) +
            SystemFormula.nutritionXP(log(), targets) + bonusXp
    val level: Int get() = LevelingEngine.level(totalXp)
    val rank: Rank get() = Rank.forLevel(level)
    val xpProgress: Pair<Int, Int> get() = LevelingEngine.progress(totalXp)
    val stats: List<Stat> get() = SystemFormula.stats(effectiveSnapshot, level)
    val quests: List<Quest>
        get() = QuestEngine.dailyQuests(effectiveSnapshot, IntakeSnapshot(log()), targets, level, "today")
    val streak: Int get() = snapshot.workoutStreakDays
    val conditionModifier: Double get() = SystemFormula.conditionModifier(effectiveSnapshot)

    // ---- Mutations ----

    fun completeOnboarding(name: String, profile: BodyProfile) {
        hunterName = name.trim().ifEmpty { "Hunter" }
        body = profile
        onboardingDone = true
        awardQuests()
    }

    /** Replace the sample data with a real snapshot read from Health Connect. */
    fun applyHealth(real: HealthSnapshot) {
        snapshot = real
        healthConnected = true
        awardQuests()
    }

    fun addWater(ml: Int) { waterMl = max(0, waterMl + ml); awardQuests() }
    fun addCaffeine(mg: Int) { caffeineMg = max(0, caffeineMg + mg) }

    fun logMeal(entry: MealEntry) { meals.add(entry); awardQuests() }
    fun removeMeal(id: String) { meals.removeAll { it.id == id } }

    fun completeGate(routine: Routine) {
        if (!clearedGateIds.contains(routine.id)) {
            clearedGateIds.add(routine.id)
            gateMinutes += routine.estMinutes
            if (awarded.add("gate.${routine.id}")) bonusXp += routine.xpReward
        }
        awardQuests()
    }

    private fun awardQuests() {
        for (q in quests) if (q.complete && awarded.add(q.id)) bonusXp += q.xpReward
    }
}
