import SwiftUI

/// Routine picker — each routine is a "Gate" to clear for XP.
struct GatesView: View {
    @ObservedObject var vm: SystemViewModel
    @State private var showBuilder = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header

                if !vm.customRoutines.isEmpty {
                    sectionLabel("Your Gates")
                    ForEach(vm.customRoutines) { routine in
                        gateLink(routine)
                            .contextMenu {
                                Button(role: .destructive) { vm.deleteCustomRoutine(routine.id) } label: {
                                    Label("Delete Gate", systemImage: "trash")
                                }
                            }
                    }
                }

                sectionLabel("System Gates")
                ForEach(RoutineLibrary.all) { gateLink($0) }

                Color.clear.frame(height: 20)
            }
            .padding(16)
        }
        .sheet(isPresented: $showBuilder) { RoutineBuilderView(vm: vm) }
    }

    private func gateLink(_ routine: Routine) -> some View {
        NavigationLink {
            GateSessionView(vm: vm, routine: routine)
        } label: {
            RoutineCard(routine: routine, cleared: vm.todayLog.completedGateIDs.contains(routine.id))
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .monospaced).weight(.bold)).tracking(2)
            .foregroundStyle(SystemTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GATES")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy)).tracking(2)
                .foregroundStyle(SystemTheme.textPrimary)
            Text("Clear a Gate to earn XP and raise STR & END. Each is a structured routine — sets, reps and rest.")
                .font(.system(.subheadline, design: .rounded)).foregroundStyle(SystemTheme.textSecondary)
            Button { showBuilder = true } label: {
                Label("Build a Gate", systemImage: "hammer.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .frame(maxWidth: .infinity).padding(.vertical, 11)
                    .background(Capsule().fill(SystemTheme.accentDeep.opacity(0.5)))
                    .overlay(Capsule().stroke(SystemTheme.accent, lineWidth: 1))
                    .foregroundStyle(SystemTheme.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}

struct RoutineCard: View {
    let routine: Routine
    let cleared: Bool

    var body: some View {
        SystemPanel {
            HStack(spacing: 14) {
                RankBadge(rank: routine.gateRank).scaleEffect(0.75).frame(width: 52, height: 56)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(routine.name).font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(SystemTheme.textPrimary)
                        if cleared {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(SystemTheme.accent)
                                .systemGlow(SystemTheme.accent, radius: 3)
                        }
                    }
                    Text(routine.subtitle).font(.caption).foregroundStyle(SystemTheme.textSecondary)
                    HStack(spacing: 12) {
                        tag("clock", "\(routine.estMinutes)m")
                        tag("square.stack.3d.up", "\(routine.totalSets) sets")
                        tag("bolt.fill", "+\(routine.xpReward) XP")
                    }
                    .padding(.top, 2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(SystemTheme.textSecondary)
            }
        }
    }

    private func tag(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 10))
            Text(text).font(.system(.caption2, design: .monospaced))
        }
        .foregroundStyle(SystemTheme.accent)
    }
}

// MARK: - Execution

@MainActor
final class GateSession: ObservableObject {
    let routine: Routine
    /// RoutineExercise.id → completed set count.
    @Published var completed: [UUID: Int] = [:]
    @Published var restRemaining = 0

    init(routine: Routine) { self.routine = routine }

    var totalSets: Int { routine.totalSets }
    var doneSets: Int { completed.values.reduce(0, +) }
    var fraction: Double { totalSets == 0 ? 0 : Double(doneSets) / Double(totalSets) }
    var isCleared: Bool { doneSets >= totalSets }

    func setCount(for re: RoutineExercise) -> Int { completed[re.id] ?? 0 }

    /// Tap set index `i` (0-based) → mark that many sets done; start rest timer.
    func tap(_ re: RoutineExercise, index: Int) {
        let current = setCount(for: re)
        let newValue = (index + 1 == current) ? index : index + 1   // tap last to undo
        completed[re.id] = max(0, min(re.sets, newValue))
        if newValue > current { restRemaining = re.restSeconds }
    }

    func tick() { if restRemaining > 0 { restRemaining -= 1 } }
    func skipRest() { restRemaining = 0 }
}

struct GateSessionView: View {
    @ObservedObject var vm: SystemViewModel
    let routine: Routine
    @StateObject private var session: GateSession
    @Environment(\.dismiss) private var dismiss
    @State private var cleared = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(vm: SystemViewModel, routine: Routine) {
        self.vm = vm
        self.routine = routine
        _session = StateObject(wrappedValue: GateSession(routine: routine))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SystemTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    progress
                    ForEach(routine.exercises) { re in
                        ExerciseCard(re: re, done: session.setCount(for: re)) { idx in
                            withAnimation(.easeOut(duration: 0.15)) { session.tap(re, index: idx) }
                        }
                    }
                    Color.clear.frame(height: 120)
                }
                .padding(16)
            }
            clearButton
            if session.restRemaining > 0 { restBanner }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in session.tick() }
        .overlay { if cleared { GateClearedOverlay(routine: routine) { dismiss() } } }
    }

    private var progress: some View {
        SystemPanel {
            VStack(spacing: 10) {
                HStack {
                    Text(routine.subtitle).font(.caption).foregroundStyle(SystemTheme.textSecondary)
                    Spacer()
                    Text("\(session.doneSets) / \(session.totalSets) sets")
                        .font(.system(.caption, design: .monospaced).weight(.bold)).foregroundStyle(SystemTheme.accent)
                }
                ProgressBar(fraction: session.fraction, color: SystemTheme.accent)
            }
        }
    }

    private var restBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer").foregroundStyle(SystemTheme.accent)
            Text("REST").font(.system(.caption, design: .monospaced).weight(.bold)).foregroundStyle(SystemTheme.textSecondary)
            Text("\(session.restRemaining)s").font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(SystemTheme.accent).systemGlow(SystemTheme.accent, radius: 4)
            Spacer()
            Button("Skip") { session.skipRest() }.foregroundStyle(SystemTheme.textSecondary)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SystemTheme.panelStroke.opacity(0.6), lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.bottom, 88)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var clearButton: some View {
        Button {
            vm.completeGate(routine)
            withAnimation(.spring) { cleared = true }
        } label: {
            Text(session.isCleared ? "CLEAR GATE  ·  +\(routine.xpReward) XP" : "Complete all sets to clear")
                .font(.system(.headline, design: .rounded).weight(.bold)).tracking(1)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Capsule().fill(session.isCleared ? SystemTheme.accentDeep : Color.white.opacity(0.06)))
                .overlay(Capsule().stroke(session.isCleared ? SystemTheme.accent : .clear, lineWidth: 1))
                .foregroundStyle(session.isCleared ? .white : SystemTheme.textSecondary)
        }
        .disabled(!session.isCleared)
        .padding(16)
    }
}

private struct ExerciseCard: View {
    let re: RoutineExercise
    let done: Int
    let onTap: (Int) -> Void

    var body: some View {
        SystemPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: re.exercise.muscle.icon).foregroundStyle(SystemTheme.accent)
                    Text(re.exercise.name).font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(SystemTheme.textPrimary)
                    Spacer()
                    Text(re.reps).font(.system(.subheadline, design: .monospaced).weight(.bold))
                        .foregroundStyle(SystemTheme.gold)
                }
                Text(re.exercise.cue).font(.caption).foregroundStyle(SystemTheme.textSecondary)
                HStack(spacing: 10) {
                    ForEach(0..<re.sets, id: \.self) { i in
                        Button { onTap(i) } label: {
                            Circle()
                                .fill(i < done ? SystemTheme.accent : Color.white.opacity(0.06))
                                .overlay(Circle().stroke(SystemTheme.panelStroke.opacity(0.6), lineWidth: 1))
                                .overlay(Text("\(i + 1)").font(.system(.caption, design: .monospaced).weight(.bold))
                                    .foregroundStyle(i < done ? .black : SystemTheme.textSecondary))
                                .frame(width: 34, height: 34)
                                .systemGlow(i < done ? SystemTheme.accent : .clear, radius: i < done ? 3 : 0)
                        }
                    }
                    Spacer()
                    Text("\(re.restSeconds)s rest").font(.caption2).foregroundStyle(SystemTheme.textSecondary)
                }
            }
        }
    }
}

private struct GateClearedOverlay: View {
    let routine: Routine
    let onDone: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 64))
                    .foregroundStyle(SystemTheme.accent).systemGlow(SystemTheme.glow, radius: 12)
                Text("GATE CLEARED").font(.system(.title, design: .rounded).weight(.heavy)).tracking(2)
                    .foregroundStyle(SystemTheme.textPrimary)
                Text("+\(routine.xpReward) XP  ·  +\(routine.estMinutes) STR min")
                    .font(.system(.headline, design: .monospaced)).foregroundStyle(SystemTheme.accent)
                Button(action: onDone) {
                    Text("RETURN").font(.system(.subheadline, design: .rounded).weight(.bold)).tracking(2)
                        .padding(.horizontal, 40).padding(.vertical, 12)
                        .overlay(Capsule().stroke(SystemTheme.accent, lineWidth: 1.5))
                        .foregroundStyle(SystemTheme.accent)
                }.padding(.top, 8)
            }
        }
    }
}
