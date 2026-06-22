import Foundation

/// A browsable movement library for the custom routine builder. (Phase 2 will
/// grow this toward a Muscle-Monster-scale 1000+ library with video cues.)
enum ExerciseLibrary {
    static let all: [Exercise] = chest + back + legs + shoulders + arms + core + cardio

    static func grouped() -> [(MuscleGroup, [Exercise])] {
        MuscleGroup.allCases.compactMap { group in
            let items = all.filter { $0.muscle == group }
            return items.isEmpty ? nil : (group, items)
        }
    }

    static func find(_ id: String) -> Exercise? { all.first { $0.id == id } }

    // MARK: Library

    static let chest: [Exercise] = [
        .init(id: "lib.bench", name: "Barbell Bench Press", muscle: .chest, cue: "Lower to mid-chest, drive up explosively.", bodyweight: false),
        .init(id: "lib.incdb", name: "Incline Dumbbell Press", muscle: .chest, cue: "45° bench, control the descent.", bodyweight: false),
        .init(id: "lib.dbpress", name: "Flat Dumbbell Press", muscle: .chest, cue: "Press up and slightly together.", bodyweight: false),
        .init(id: "lib.fly", name: "Cable Fly", muscle: .chest, cue: "Slight elbow bend, hug the midline.", bodyweight: false),
        .init(id: "lib.pushup", name: "Push-Up", muscle: .chest, cue: "Body in a straight line.", bodyweight: true),
        .init(id: "lib.dip", name: "Chest Dip", muscle: .chest, cue: "Lean forward, full stretch.", bodyweight: true),
    ]

    static let back: [Exercise] = [
        .init(id: "lib.deadlift", name: "Deadlift", muscle: .back, cue: "Bar over mid-foot, flat back.", bodyweight: false),
        .init(id: "lib.pullup", name: "Pull-Up", muscle: .back, cue: "Full hang to chin over bar.", bodyweight: true),
        .init(id: "lib.row", name: "Barbell Row", muscle: .back, cue: "Hinge ~45°, pull to navel.", bodyweight: false),
        .init(id: "lib.dbrow", name: "Dumbbell Row", muscle: .back, cue: "One arm, flat back, full stretch.", bodyweight: false),
        .init(id: "lib.lat", name: "Lat Pulldown", muscle: .back, cue: "Drive elbows down and back.", bodyweight: false),
        .init(id: "lib.cablerow", name: "Seated Cable Row", muscle: .back, cue: "Proud chest, squeeze shoulder blades.", bodyweight: false),
    ]

    static let legs: [Exercise] = [
        .init(id: "lib.squat", name: "Back Squat", muscle: .legs, cue: "Break at hips, depth below parallel.", bodyweight: false),
        .init(id: "lib.frontsquat", name: "Front Squat", muscle: .legs, cue: "Elbows high, upright torso.", bodyweight: false),
        .init(id: "lib.rdl", name: "Romanian Deadlift", muscle: .legs, cue: "Soft knees, push hips back.", bodyweight: false),
        .init(id: "lib.legpress", name: "Leg Press", muscle: .legs, cue: "Knees track toes, don't lock out.", bodyweight: false),
        .init(id: "lib.lunge", name: "Walking Lunge", muscle: .legs, cue: "Long stride, knee tracks toes.", bodyweight: false),
        .init(id: "lib.calf", name: "Calf Raise", muscle: .legs, cue: "Full stretch, pause at top.", bodyweight: false),
        .init(id: "lib.bwsquat", name: "Bodyweight Squat", muscle: .legs, cue: "Chest up, heels down.", bodyweight: true),
    ]

    static let shoulders: [Exercise] = [
        .init(id: "lib.ohp", name: "Overhead Press", muscle: .shoulders, cue: "Brace core, press straight overhead.", bodyweight: false),
        .init(id: "lib.latraise", name: "Lateral Raise", muscle: .shoulders, cue: "Lead with elbows, no swinging.", bodyweight: false),
        .init(id: "lib.facepull", name: "Face Pull", muscle: .shoulders, cue: "Pull to forehead, externally rotate.", bodyweight: false),
        .init(id: "lib.reardelt", name: "Rear Delt Fly", muscle: .shoulders, cue: "Soft elbows, squeeze the rear delts.", bodyweight: false),
        .init(id: "lib.pike", name: "Pike Push-Up", muscle: .shoulders, cue: "Hips high, crown toward floor.", bodyweight: true),
    ]

    static let arms: [Exercise] = [
        .init(id: "lib.curl", name: "Dumbbell Curl", muscle: .arms, cue: "No swing, squeeze at top.", bodyweight: false),
        .init(id: "lib.hammer", name: "Hammer Curl", muscle: .arms, cue: "Neutral grip, control down.", bodyweight: false),
        .init(id: "lib.pushdown", name: "Triceps Pushdown", muscle: .arms, cue: "Elbows pinned, full lockout.", bodyweight: false),
        .init(id: "lib.skull", name: "Skull Crusher", muscle: .arms, cue: "Elbows still, lower to forehead.", bodyweight: false),
        .init(id: "lib.diamond", name: "Diamond Push-Up", muscle: .arms, cue: "Hands together under chest.", bodyweight: true),
    ]

    static let core: [Exercise] = [
        .init(id: "lib.plank", name: "Plank", muscle: .core, cue: "Squeeze glutes, neutral spine.", bodyweight: true),
        .init(id: "lib.hanging", name: "Hanging Knee Raise", muscle: .core, cue: "Curl pelvis up, no swing.", bodyweight: true),
        .init(id: "lib.crunch", name: "Cable Crunch", muscle: .core, cue: "Round the spine, hips fixed.", bodyweight: false),
        .init(id: "lib.russian", name: "Russian Twist", muscle: .core, cue: "Rotate from the torso.", bodyweight: true),
        .init(id: "lib.deadbug", name: "Dead Bug", muscle: .core, cue: "Low back glued to the floor.", bodyweight: true),
    ]

    static let cardio: [Exercise] = [
        .init(id: "lib.run", name: "Run", muscle: .cardio, cue: "Steady, relaxed cadence.", bodyweight: true),
        .init(id: "lib.rowerg", name: "Rowing Erg", muscle: .cardio, cue: "Legs–core–arms, then reverse.", bodyweight: false),
        .init(id: "lib.burpee", name: "Burpee", muscle: .cardio, cue: "Chest to floor, jump at the top.", bodyweight: true),
        .init(id: "lib.mtn", name: "Mountain Climbers", muscle: .cardio, cue: "Fast knees, tight core.", bodyweight: true),
        .init(id: "lib.jumprope", name: "Jump Rope", muscle: .cardio, cue: "Light bounces, wrists turn the rope.", bodyweight: true),
    ]
}
