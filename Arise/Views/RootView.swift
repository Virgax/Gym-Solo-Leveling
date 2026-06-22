import SwiftUI

struct RootView: View {
    @StateObject private var vm = SystemViewModel()
    @State private var showSettings = false

    var body: some View {
        ZStack {
            SystemTheme.background.ignoresSafeArea()
            BackdropGrid().ignoresSafeArea()

            switch vm.phase {
            case .needsAuthorization: AuthGate(vm: vm)
            case .loading: LoadingView()
            case .unavailable: UnavailableView()
            case .ready: content
            }

            if let level = vm.pendingLevelUp {
                LevelUpOverlay(level: level) { withAnimation { vm.acknowledgeLevelUp() } }
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
        .task { await vm.start() }
        .sheet(isPresented: $showSettings) { SettingsSheet(vm: vm) }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 18) {
                topBar
                if vm.usingMockData { mockBanner }
                StatusWindowView(vm: vm)
                QuestWindowView(quests: vm.quests)
                Color.clear.frame(height: 20)
            }
            .padding(16)
        }
        .refreshable { await vm.refresh() }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("THE SYSTEM")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .tracking(3)
                    .foregroundStyle(SystemTheme.accent)
                Text("Player: \(vm.profile.name)")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(SystemTheme.textSecondary)
            }
            Spacer()
            Button { Task { await vm.refresh() } } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(SystemTheme.accent)
            }
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(SystemTheme.textSecondary)
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
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(SystemTheme.gold.opacity(0.12)))
    }
}

// MARK: - Phase screens

private struct AuthGate: View {
    @ObservedObject var vm: SystemViewModel
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "applewatch.side.right")
                .font(.system(size: 56)).foregroundStyle(SystemTheme.accent).systemGlow()
            Text("THE SYSTEM AWAITS")
                .font(.system(.title2, design: .rounded).weight(.heavy)).tracking(2)
                .foregroundStyle(SystemTheme.textPrimary)
            Text("Connect Apple Health so the System can read your training, recovery and body data — including anything your RingConn ring and Eufy scale sync in.")
                .font(.system(.subheadline, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(SystemTheme.textSecondary)
                .padding(.horizontal, 32)
            Button { Task { await vm.start() } } label: {
                Text("AWAKEN")
                    .font(.system(.headline, design: .rounded).weight(.bold)).tracking(2)
                    .padding(.horizontal, 48).padding(.vertical, 14)
                    .background(Capsule().fill(SystemTheme.accentDeep))
                    .overlay(Capsule().stroke(SystemTheme.accent, lineWidth: 1))
                    .foregroundStyle(.white)
                    .systemGlow()
            }
            Spacer()
        }
        .padding()
    }
}

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView().tint(SystemTheme.accent)
            Text("Reading your stats…")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(SystemTheme.textSecondary)
        }
    }
}

private struct UnavailableView: View {
    var body: some View {
        Text("Health data isn't available on this device.")
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(SystemTheme.textSecondary)
            .padding()
    }
}

private struct SettingsSheet: View {
    @ObservedObject var vm: SystemViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Hunter") {
                    TextField("Name", text: $name)
                        .onSubmit { vm.setName(name) }
                }
                Section("Progress") {
                    LabeledContent("Level", value: "\(vm.profile.level)")
                    LabeledContent("Rank", value: vm.profile.rank.title)
                    LabeledContent("Total XP", value: "\(vm.profile.totalXP)")
                }
                Section {
                    Button("Reset Progress", role: .destructive) { vm.resetProgress() }
                } footer: {
                    Text("Wipes levels, XP and quest history. Health data is untouched.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { vm.setName(name); dismiss() }
                }
            }
            .onAppear { name = vm.profile.name }
        }
        .preferredColorScheme(.dark)
    }
}

/// Subtle perspective grid behind everything for the "interface" vibe.
private struct BackdropGrid: View {
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
