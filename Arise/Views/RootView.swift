import SwiftUI

struct RootView: View {
    @StateObject private var vm = SystemViewModel()

    var body: some View {
        ZStack {
            SystemTheme.background.ignoresSafeArea()
            BackdropGrid().ignoresSafeArea()

            switch vm.phase {
            case .loading: LoadingView()
            case .onboarding: OnboardingView(vm: vm)
            case .unavailable: UnavailableView()
            case .ready: MainTabs(vm: vm)
            }

            if let level = vm.pendingLevelUp {
                LevelUpOverlay(level: level) { withAnimation { vm.acknowledgeLevelUp() } }
                    .transition(.opacity).zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
        .task { await vm.start() }
    }
}

private struct MainTabs: View {
    @ObservedObject var vm: SystemViewModel

    var body: some View {
        TabView {
            StatusTab(vm: vm)
                .tabItem { Label("Status", systemImage: "person.crop.square.badge.camera") }
            NavigationStack { GatesView(vm: vm).background(SystemTheme.background) }
                .tabItem { Label("Gates", systemImage: "square.grid.2x2.fill") }
            FuelView(vm: vm)
                .tabItem { Label("Fuel", systemImage: "fork.knife") }
            QuestsTab(vm: vm)
                .tabItem { Label("Quests", systemImage: "checklist") }
        }
        .tint(SystemTheme.accent)
    }
}

// MARK: - Tabs

private struct StatusTab: View {
    @ObservedObject var vm: SystemViewModel
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                topBar
                if vm.penaltyActive { penaltyBanner }
                streakChip
                if vm.usingMockData { mockBanner }
                StatusWindowView(vm: vm)
                if let body = vm.profile.bodyProfile { BodyStatsPanel(body: body) }
                Color.clear.frame(height: 20)
            }
            .padding(16)
        }
        .refreshable { await vm.refresh() }
        .sheet(isPresented: $showSettings) { SettingsSheet(vm: vm) }
        .background(SystemTheme.background)
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("THE SYSTEM").font(.system(.caption, design: .monospaced).weight(.bold)).tracking(3)
                    .foregroundStyle(SystemTheme.accent)
                Text("Player: \(vm.profile.name)").font(.system(.caption2, design: .rounded))
                    .foregroundStyle(SystemTheme.textSecondary)
            }
            Spacer()
            Button { Task { await vm.refresh() } } label: {
                Image(systemName: "arrow.triangle.2.circlepath").foregroundStyle(SystemTheme.accent)
            }
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill").foregroundStyle(SystemTheme.textSecondary)
            }
        }
        .font(.title3)
    }

    private var mockBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
            Text("Showing sample data — no health metrics found yet. Pull to refresh once your ring/watch has synced.")
                .font(.system(.caption2, design: .rounded))
        }
        .foregroundStyle(SystemTheme.gold)
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(SystemTheme.gold.opacity(0.12)))
    }

    private var streakChip: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .foregroundStyle(vm.streak > 0 ? SystemTheme.gold : SystemTheme.textSecondary)
                .systemGlow(vm.streak > 0 ? SystemTheme.gold : .clear, radius: 4)
            Text(vm.streak > 0 ? "\(vm.streak)-day streak" : "No active streak")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(SystemTheme.textPrimary)
            Spacer()
            Text("Clear all required quests daily to keep it.")
                .font(.system(size: 10, design: .rounded)).foregroundStyle(SystemTheme.textSecondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(SystemTheme.panel))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SystemTheme.panelStroke.opacity(0.4), lineWidth: 1))
    }

    private var penaltyBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(SystemTheme.danger)
            VStack(alignment: .leading, spacing: 2) {
                Text("PENALTY ZONE").font(.system(.subheadline, design: .rounded).weight(.heavy)).tracking(1)
                    .foregroundStyle(SystemTheme.danger)
                Text("You missed yesterday's required quests. Clear today's to redeem yourself, Hunter.")
                    .font(.system(size: 11, design: .rounded)).foregroundStyle(SystemTheme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(SystemTheme.danger.opacity(0.14)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SystemTheme.danger.opacity(0.6), lineWidth: 1))
    }
}

private struct QuestsTab: View {
    @ObservedObject var vm: SystemViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                group("Training", .training)
                group("Fuel", .fuel)
                group("Recovery", .recovery)
                Color.clear.frame(height: 20)
            }
            .padding(16)
        }
        .background(SystemTheme.background)
    }

    @ViewBuilder private func group(_ title: String, _ cat: Quest.Category) -> some View {
        let qs = vm.quests.filter { $0.category == cat }
        if !qs.isEmpty { QuestWindowView(title: "\(title) Quests", quests: qs) }
    }
}

// MARK: - Phase screens

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView().tint(SystemTheme.accent)
            Text("Reading your stats…").font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(SystemTheme.textSecondary)
        }
    }
}

private struct UnavailableView: View {
    var body: some View {
        Text("Health data isn't available on this device.")
            .font(.system(.subheadline, design: .rounded)).foregroundStyle(SystemTheme.textSecondary).padding()
    }
}

private struct SettingsSheet: View {
    @ObservedObject var vm: SystemViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Hunter") {
                    TextField("Name", text: $name).onSubmit { vm.setName(name) }
                }
                Section("Progress") {
                    LabeledContent("Level", value: "\(vm.profile.level)")
                    LabeledContent("Rank", value: vm.profile.rank.title)
                    LabeledContent("Total XP", value: "\(vm.profile.totalXP)")
                }
                if let b = vm.profile.bodyProfile {
                    Section("Targets") {
                        LabeledContent("Calories", value: "\(b.targets.calories) kcal")
                        LabeledContent("Protein", value: "\(b.targets.proteinG) g")
                        LabeledContent("Water", value: "\(b.targets.waterMl) mL")
                        LabeledContent("BMI", value: String(format: "%.1f (%@)", b.bmi, b.bmiCategory.rawValue))
                    }
                }
                Section {
                    Button("Reset & Re-run Setup", role: .destructive) { vm.resetProgress(); dismiss() }
                } footer: {
                    Text("Wipes levels, XP, logs and body setup. Health data is untouched.")
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { vm.setName(name); dismiss() } } }
            .onAppear { name = vm.profile.name }
        }
        .preferredColorScheme(.dark)
    }
}

/// Subtle perspective grid behind everything for the "interface" vibe.
struct BackdropGrid: View {
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 44
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width { path.move(to: .init(x: x, y: 0)); path.addLine(to: .init(x: x, y: size.height)); x += spacing }
            var y: CGFloat = 0
            while y <= size.height { path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: size.width, y: y)); y += spacing }
            ctx.stroke(path, with: .color(SystemTheme.accent.opacity(0.05)), lineWidth: 0.5)
        }
    }
}
