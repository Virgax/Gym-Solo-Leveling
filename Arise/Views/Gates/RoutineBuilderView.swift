import SwiftUI

/// Compose a custom Gate from the exercise library: pick movements, set
/// sets/reps/rest, name it, and save.
struct RoutineBuilderView: View {
    @ObservedObject var vm: SystemViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var focus: MuscleGroup = .fullBody
    @State private var gateRank: Rank = .d
    @State private var items: [RoutineExercise] = []
    @State private var picking = false

    private var estMinutes: Int {
        let secs = items.reduce(0) { $0 + $1.sets * ($1.restSeconds + 40) }
        return max(5, Int((Double(secs) / 60).rounded(.up)))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Gate") {
                    TextField("Name (e.g. Upper Power)", text: $name)
                    Picker("Focus", selection: $focus) {
                        ForEach(MuscleGroup.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    Picker("Difficulty", selection: $gateRank) {
                        ForEach([Rank.e, .d, .c, .b, .a, .s], id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }

                Section("Exercises · ~\(estMinutes) min") {
                    if items.isEmpty {
                        Text("Add movements from the library.").foregroundStyle(.secondary)
                    }
                    ForEach($items) { $item in
                        BuilderRow(item: $item)
                    }
                    .onDelete { items.remove(atOffsets: $0) }
                    Button { picking = true } label: {
                        Label("Add exercise", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Build a Gate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(items.isEmpty || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $picking) {
                ExercisePickerSheet { ex in
                    items.append(RoutineExercise(exercise: ex, sets: 3, reps: "8–12", restSeconds: 75))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        let routine = Routine(
            id: "custom.\(UUID().uuidString)",
            name: name.trimmingCharacters(in: .whitespaces),
            subtitle: "Custom · \(focus.label)",
            gateRank: gateRank,
            focus: focus,
            estMinutes: estMinutes,
            exercises: items
        )
        vm.addCustomRoutine(routine)
        dismiss()
    }
}

private struct BuilderRow: View {
    @Binding var item: RoutineExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.exercise.muscle.icon).foregroundStyle(SystemTheme.accent)
                Text(item.exercise.name).font(.subheadline.weight(.semibold))
            }
            HStack(spacing: 12) {
                Stepper("Sets \(item.sets)", value: $item.sets, in: 1...10).font(.caption)
            }
            HStack(spacing: 12) {
                TextField("Reps", text: $item.reps)
                    .textFieldStyle(.roundedBorder).frame(width: 90)
                Spacer()
                Picker("Rest", selection: $item.restSeconds) {
                    ForEach([30, 45, 60, 75, 90, 120, 150], id: \.self) { Text("\($0)s rest").tag($0) }
                }
                .pickerStyle(.menu)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Library browser grouped by muscle group; taps add to the draft.
struct ExercisePickerSheet: View {
    let onPick: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(ExerciseLibrary.grouped(), id: \.0) { group, exercises in
                    Section(group.label) {
                        ForEach(exercises) { ex in
                            Button {
                                onPick(ex); dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: ex.muscle.icon).foregroundStyle(SystemTheme.accent).frame(width: 24)
                                    VStack(alignment: .leading) {
                                        Text(ex.name).foregroundStyle(.primary)
                                        Text(ex.cue).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if ex.bodyweight { Image(systemName: "figure.walk").font(.caption).foregroundStyle(.secondary) }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }
}
