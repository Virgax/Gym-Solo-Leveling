package com.virgax.arise.domain

enum class MuscleGroup(val label: String) {
    CHEST("Chest"), BACK("Back"), LEGS("Legs"), SHOULDERS("Shoulders"),
    ARMS("Arms"), CORE("Core"), FULL_BODY("Full Body"), CARDIO("Cardio")
}

data class Exercise(val id: String, val name: String, val muscle: MuscleGroup, val cue: String, val bodyweight: Boolean)

data class RoutineExercise(val exercise: Exercise, val sets: Int, val reps: String, val restSeconds: Int)

data class Routine(
    val id: String,
    val name: String,
    val subtitle: String,
    val gateRank: Rank,
    val focus: MuscleGroup,
    val estMinutes: Int,
    val exercises: List<RoutineExercise>,
) {
    val totalSets: Int get() = exercises.sumOf { it.sets }
    val xpReward: Int
        get() {
            val rankBonus = Rank.entries.indexOf(gateRank) * 25
            return 60 + totalSets * 6 + rankBonus
        }
}

object RoutineLibrary {
    val all: List<Routine> = listOf(push(), pull(), legs(), fullBody(), core(), home())

    private fun ex(id: String, name: String, m: MuscleGroup, cue: String, bw: Boolean = false) =
        Exercise(id, name, m, cue, bw)

    private fun push() = Routine(
        "gate.push", "Push Gate", "Chest · Shoulders · Triceps", Rank.D, MuscleGroup.CHEST, 45,
        listOf(
            RoutineExercise(ex("ex.bench", "Barbell Bench Press", MuscleGroup.CHEST, "Lower to mid-chest, drive up."), 4, "6–10", 120),
            RoutineExercise(ex("ex.ohp", "Overhead Press", MuscleGroup.SHOULDERS, "Brace core, press overhead."), 3, "8–10", 90),
            RoutineExercise(ex("ex.incdb", "Incline Dumbbell Press", MuscleGroup.CHEST, "45° bench, control descent."), 3, "10–12", 75),
            RoutineExercise(ex("ex.lat", "Lateral Raise", MuscleGroup.SHOULDERS, "Lead with elbows."), 3, "12–15", 60),
            RoutineExercise(ex("ex.push", "Triceps Pushdown", MuscleGroup.ARMS, "Elbows pinned, full lockout."), 3, "12–15", 60),
        )
    )

    private fun pull() = Routine(
        "gate.pull", "Pull Gate", "Back · Biceps · Rear delts", Rank.D, MuscleGroup.BACK, 45,
        listOf(
            RoutineExercise(ex("ex.pullup", "Pull-Up", MuscleGroup.BACK, "Full hang to chin over bar.", true), 4, "AMRAP", 120),
            RoutineExercise(ex("ex.row", "Barbell Row", MuscleGroup.BACK, "Hinge ~45°, pull to navel."), 4, "8–10", 90),
            RoutineExercise(ex("ex.pulldown", "Lat Pulldown", MuscleGroup.BACK, "Drive elbows down and back."), 3, "10–12", 75),
            RoutineExercise(ex("ex.face", "Face Pull", MuscleGroup.SHOULDERS, "Pull to forehead."), 3, "15–20", 60),
            RoutineExercise(ex("ex.curl", "Dumbbell Curl", MuscleGroup.ARMS, "No swing, squeeze at top."), 3, "10–12", 60),
        )
    )

    private fun legs() = Routine(
        "gate.legs", "Leg Gate", "Quads · Hamstrings · Glutes", Rank.C, MuscleGroup.LEGS, 55,
        listOf(
            RoutineExercise(ex("ex.squat", "Back Squat", MuscleGroup.LEGS, "Depth below parallel."), 5, "5–8", 150),
            RoutineExercise(ex("ex.rdl", "Romanian Deadlift", MuscleGroup.LEGS, "Soft knees, push hips back."), 4, "8–10", 120),
            RoutineExercise(ex("ex.lunge", "Walking Lunge", MuscleGroup.LEGS, "Long stride, knee tracks toes."), 3, "12 / leg", 90),
            RoutineExercise(ex("ex.calf", "Calf Raise", MuscleGroup.LEGS, "Full stretch, pause at top."), 4, "15–20", 60),
        )
    )

    private fun fullBody() = Routine(
        "gate.full", "Full-Body Gate", "Total-body strength", Rank.C, MuscleGroup.FULL_BODY, 50,
        listOf(
            RoutineExercise(ex("ex.dl", "Deadlift", MuscleGroup.BACK, "Bar over mid-foot, flat back."), 4, "5", 150),
            RoutineExercise(ex("ex.gob", "Goblet Squat", MuscleGroup.LEGS, "Upright torso."), 3, "10–12", 90),
            RoutineExercise(ex("ex.pushup", "Push-Up", MuscleGroup.CHEST, "Straight line.", true), 3, "AMRAP", 75),
            RoutineExercise(ex("ex.dbrow", "Dumbbell Row", MuscleGroup.BACK, "Flat back, full stretch."), 3, "10–12", 75),
            RoutineExercise(ex("ex.plank", "Plank", MuscleGroup.CORE, "Squeeze glutes.", true), 3, "45s", 45),
        )
    )

    private fun core() = Routine(
        "gate.core", "Core Gate", "Abs · Obliques · Stability", Rank.E, MuscleGroup.CORE, 20,
        listOf(
            RoutineExercise(ex("ex.hang", "Hanging Knee Raise", MuscleGroup.CORE, "Curl pelvis up.", true), 3, "12–15", 45),
            RoutineExercise(ex("ex.crunch", "Cable Crunch", MuscleGroup.CORE, "Round the spine."), 3, "15–20", 45),
            RoutineExercise(ex("ex.russ", "Russian Twist", MuscleGroup.CORE, "Rotate from the torso.", true), 3, "20", 30),
            RoutineExercise(ex("ex.plank2", "Plank", MuscleGroup.CORE, "Hold tight.", true), 3, "60s", 45),
        )
    )

    private fun home() = Routine(
        "gate.home", "Home Gate", "No equipment needed", Rank.E, MuscleGroup.FULL_BODY, 25,
        listOf(
            RoutineExercise(ex("ex.bwsq", "Bodyweight Squat", MuscleGroup.LEGS, "Chest up, heels down.", true), 4, "20", 45),
            RoutineExercise(ex("ex.pushup2", "Push-Up", MuscleGroup.CHEST, "Lower under control.", true), 4, "AMRAP", 60),
            RoutineExercise(ex("ex.rlunge", "Reverse Lunge", MuscleGroup.LEGS, "Step back, drop the knee.", true), 3, "12 / leg", 45),
            RoutineExercise(ex("ex.mtn", "Mountain Climbers", MuscleGroup.CARDIO, "Fast knees, tight core.", true), 3, "40s", 30),
            RoutineExercise(ex("ex.plank3", "Plank", MuscleGroup.CORE, "Neutral spine.", true), 3, "45s", 30),
        )
    )
}
