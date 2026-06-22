import SwiftUI

enum MuscleGroup: String, Codable, CaseIterable {
    case chest, back, legs, shoulders, arms, core, fullBody, cardio
    var label: String {
        switch self {
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .legs: return "figure.run"
        case .shoulders: return "figure.arms.open"
        case .arms: return "dumbbell.fill"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.mixed.cardio"
        case .cardio: return "heart.fill"
        }
    }
}

/// A movement in the library. Mirrors a Muscle-Monster-style exercise card.
struct Exercise: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var muscle: MuscleGroup
    var cue: String          // one-line execution cue
    var bodyweight: Bool
}

/// An exercise as scheduled inside a routine: sets × reps + rest.
struct RoutineExercise: Codable, Identifiable, Hashable {
    var id = UUID()
    var exercise: Exercise
    var sets: Int
    var reps: String         // "8–12", "30s", "AMRAP"
    var restSeconds: Int
}

/// A "Gate" — a structured routine the Hunter can clear for XP.
struct Routine: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var subtitle: String
    var gateRank: Rank       // difficulty, shown as a gate rank
    var focus: MuscleGroup
    var estMinutes: Int
    var exercises: [RoutineExercise]

    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets } }
    /// XP scales with volume + difficulty.
    var xpReward: Int {
        let rankBonus = (Rank.allCases.firstIndex(of: gateRank) ?? 0) * 25
        return 60 + totalSets * 6 + rankBonus
    }
    var color: Color { gateRank.color }
}

/// Built-in starter Gates. (Phase 2: AI-generated plans + custom builder,
/// video cues, and a full 1000+ movement library like Muscle Monster.)
enum RoutineLibrary {
    static let all: [Routine] = [push, pull, legs, fullBody, core, homeBodyweight]

    static let push = Routine(
        id: "gate.push", name: "Push Gate", subtitle: "Chest · Shoulders · Triceps",
        gateRank: .d, focus: .chest, estMinutes: 45,
        exercises: [
            RoutineExercise(exercise: .init(id: "ex.bench", name: "Barbell Bench Press", muscle: .chest, cue: "Lower to mid-chest, drive up explosively.", bodyweight: false), sets: 4, reps: "6–10", restSeconds: 120),
            RoutineExercise(exercise: .init(id: "ex.ohp", name: "Overhead Press", muscle: .shoulders, cue: "Brace core, press straight overhead.", bodyweight: false), sets: 3, reps: "8–10", restSeconds: 90),
            RoutineExercise(exercise: .init(id: "ex.incdb", name: "Incline Dumbbell Press", muscle: .chest, cue: "45° bench, control the descent.", bodyweight: false), sets: 3, reps: "10–12", restSeconds: 75),
            RoutineExercise(exercise: .init(id: "ex.latraise", name: "Lateral Raise", muscle: .shoulders, cue: "Lead with elbows, no swinging.", bodyweight: false), sets: 3, reps: "12–15", restSeconds: 60),
            RoutineExercise(exercise: .init(id: "ex.pushdown", name: "Triceps Pushdown", muscle: .arms, cue: "Elbows pinned, full lockout.", bodyweight: false), sets: 3, reps: "12–15", restSeconds: 60),
        ])

    static let pull = Routine(
        id: "gate.pull", name: "Pull Gate", subtitle: "Back · Biceps · Rear delts",
        gateRank: .d, focus: .back, estMinutes: 45,
        exercises: [
            RoutineExercise(exercise: .init(id: "ex.pullup", name: "Pull-Up", muscle: .back, cue: "Full hang to chin over bar.", bodyweight: true), sets: 4, reps: "AMRAP", restSeconds: 120),
            RoutineExercise(exercise: .init(id: "ex.row", name: "Barbell Row", muscle: .back, cue: "Hinge ~45°, pull to navel.", bodyweight: false), sets: 4, reps: "8–10", restSeconds: 90),
            RoutineExercise(exercise: .init(id: "ex.lat", name: "Lat Pulldown", muscle: .back, cue: "Drive elbows down and back.", bodyweight: false), sets: 3, reps: "10–12", restSeconds: 75),
            RoutineExercise(exercise: .init(id: "ex.facepull", name: "Face Pull", muscle: .shoulders, cue: "Pull to forehead, externally rotate.", bodyweight: false), sets: 3, reps: "15–20", restSeconds: 60),
            RoutineExercise(exercise: .init(id: "ex.curl", name: "Dumbbell Curl", muscle: .arms, cue: "No swing, squeeze at top.", bodyweight: false), sets: 3, reps: "10–12", restSeconds: 60),
        ])

    static let legs = Routine(
        id: "gate.legs", name: "Leg Gate", subtitle: "Quads · Hamstrings · Glutes",
        gateRank: .c, focus: .legs, estMinutes: 55,
        exercises: [
            RoutineExercise(exercise: .init(id: "ex.squat", name: "Back Squat", muscle: .legs, cue: "Break at hips, depth below parallel.", bodyweight: false), sets: 5, reps: "5–8", restSeconds: 150),
            RoutineExercise(exercise: .init(id: "ex.rdl", name: "Romanian Deadlift", muscle: .legs, cue: "Soft knees, push hips back.", bodyweight: false), sets: 4, reps: "8–10", restSeconds: 120),
            RoutineExercise(exercise: .init(id: "ex.lunge", name: "Walking Lunge", muscle: .legs, cue: "Long stride, knee tracks toes.", bodyweight: false), sets: 3, reps: "12 / leg", restSeconds: 90),
            RoutineExercise(exercise: .init(id: "ex.calf", name: "Calf Raise", muscle: .legs, cue: "Full stretch, pause at top.", bodyweight: false), sets: 4, reps: "15–20", restSeconds: 60),
        ])

    static let fullBody = Routine(
        id: "gate.full", name: "Full-Body Gate", subtitle: "Total-body strength",
        gateRank: .c, focus: .fullBody, estMinutes: 50,
        exercises: [
            RoutineExercise(exercise: .init(id: "ex.dl", name: "Deadlift", muscle: .back, cue: "Bar over mid-foot, flat back.", bodyweight: false), sets: 4, reps: "5", restSeconds: 150),
            RoutineExercise(exercise: .init(id: "ex.squat2", name: "Goblet Squat", muscle: .legs, cue: "Elbows inside knees, upright torso.", bodyweight: false), sets: 3, reps: "10–12", restSeconds: 90),
            RoutineExercise(exercise: .init(id: "ex.press", name: "Push-Up", muscle: .chest, cue: "Body in a straight line.", bodyweight: true), sets: 3, reps: "AMRAP", restSeconds: 75),
            RoutineExercise(exercise: .init(id: "ex.row2", name: "Dumbbell Row", muscle: .back, cue: "One arm, flat back, full stretch.", bodyweight: false), sets: 3, reps: "10–12", restSeconds: 75),
            RoutineExercise(exercise: .init(id: "ex.plank", name: "Plank", muscle: .core, cue: "Squeeze glutes, neutral spine.", bodyweight: true), sets: 3, reps: "45s", restSeconds: 45),
        ])

    static let core = Routine(
        id: "gate.core", name: "Core Gate", subtitle: "Abs · Obliques · Stability",
        gateRank: .e, focus: .core, estMinutes: 20,
        exercises: [
            RoutineExercise(exercise: .init(id: "ex.hanging", name: "Hanging Knee Raise", muscle: .core, cue: "Curl pelvis up, no swing.", bodyweight: true), sets: 3, reps: "12–15", restSeconds: 45),
            RoutineExercise(exercise: .init(id: "ex.crunch", name: "Cable Crunch", muscle: .core, cue: "Round the spine, hips fixed.", bodyweight: false), sets: 3, reps: "15–20", restSeconds: 45),
            RoutineExercise(exercise: .init(id: "ex.russ", name: "Russian Twist", muscle: .core, cue: "Rotate from the torso.", bodyweight: true), sets: 3, reps: "20", restSeconds: 30),
            RoutineExercise(exercise: .init(id: "ex.plank2", name: "Plank", muscle: .core, cue: "Hold tight, breathe steady.", bodyweight: true), sets: 3, reps: "60s", restSeconds: 45),
        ])

    static let homeBodyweight = Routine(
        id: "gate.home", name: "Home Gate", subtitle: "No equipment needed",
        gateRank: .e, focus: .fullBody, estMinutes: 25,
        exercises: [
            RoutineExercise(exercise: .init(id: "ex.bwsquat", name: "Bodyweight Squat", muscle: .legs, cue: "Chest up, heels down.", bodyweight: true), sets: 4, reps: "20", restSeconds: 45),
            RoutineExercise(exercise: .init(id: "ex.pushup2", name: "Push-Up", muscle: .chest, cue: "Lower under control.", bodyweight: true), sets: 4, reps: "AMRAP", restSeconds: 60),
            RoutineExercise(exercise: .init(id: "ex.lunge2", name: "Reverse Lunge", muscle: .legs, cue: "Step back, drop the knee.", bodyweight: true), sets: 3, reps: "12 / leg", restSeconds: 45),
            RoutineExercise(exercise: .init(id: "ex.mtn", name: "Mountain Climbers", muscle: .cardio, cue: "Fast knees, tight core.", bodyweight: true), sets: 3, reps: "40s", restSeconds: 30),
            RoutineExercise(exercise: .init(id: "ex.plank3", name: "Plank", muscle: .core, cue: "Neutral spine, no sag.", bodyweight: true), sets: 3, reps: "45s", restSeconds: 30),
        ])
}
