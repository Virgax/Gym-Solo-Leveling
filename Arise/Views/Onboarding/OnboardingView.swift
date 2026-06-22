import SwiftUI

/// First-launch setup. Flow:
/// 1) Welcome + Health permission   2) Body metrics (prefilled from Health if
/// available, else manual)   3) Goal   4) Computed targets summary.
struct OnboardingView: View {
    @ObservedObject var vm: SystemViewModel
    @State private var step = 0

    // Editable fields (seeded from HealthKit prefill on appear).
    @State private var name = "Hunter"
    @State private var sex: Sex = .male
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: .now)!
    @State private var heightCm: Double = 175
    @State private var weightKg: Double = 75
    @State private var activity: ActivityLevel = .moderate
    @State private var goal: Goal = .maintain
    @State private var didSeed = false

    private var profile: BodyProfile {
        BodyProfile(sex: sex, birthDate: birthDate, heightCm: heightCm,
                    weightKg: weightKg, activity: activity, goal: goal)
    }

    var body: some View {
        VStack(spacing: 0) {
            ProgressDots(count: 4, index: step).padding(.top, 16)
            TabView(selection: $step) {
                welcome.tag(0)
                metrics.tag(1)
                goalStep.tag(2)
                summary.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)

            controls.padding(20)
        }
        .background(SystemTheme.background.ignoresSafeArea())
        .onAppear(perform: seedFromPrefill)
    }

    // MARK: Steps

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 60)).foregroundStyle(SystemTheme.accent).systemGlow()
            Text("THE SYSTEM HAS\nCHOSEN YOU")
                .multilineTextAlignment(.center)
                .font(.system(.largeTitle, design: .rounded).weight(.heavy)).tracking(1)
                .foregroundStyle(SystemTheme.textPrimary)
            Text("Grant Health access so the System can read your training, sleep, heart and body data — including anything your RingConn ring and Eufy scale sync into Apple Health. Anything it can't read, you'll enter yourself.")
                .multilineTextAlignment(.center)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(SystemTheme.textSecondary)
                .padding(.horizontal, 28)
            Spacer()
        }
        .padding()
    }

    private var metrics: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                stepTitle("Your Vessel", subtitle: vm.bodyPrefill.weightKg != nil ? "Prefilled from Apple Health — adjust if needed." : "Enter your details so the System can calibrate.")

                field("Hunter name") {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder).foregroundStyle(.black)
                }

                field("Sex (for metabolic math)") {
                    Picker("", selection: $sex) {
                        ForEach(Sex.allCases) { Text($0.label).tag($0) }
                    }.pickerStyle(.segmented)
                }

                field("Date of birth · Age \(profile.age)") {
                    DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact).labelsHidden().colorScheme(.dark)
                }

                slider("Height", value: $heightCm, range: 120...220, unit: "cm")
                slider("Weight", value: $weightKg, range: 35...200, unit: "kg")

                field("Activity level") {
                    Picker("", selection: $activity) {
                        ForEach(ActivityLevel.allCases) { Text($0.label).tag($0) }
                    }.pickerStyle(.menu).tint(SystemTheme.accent)
                    Text(activity.detail).font(.caption).foregroundStyle(SystemTheme.textSecondary)
                }

                liveBMI
            }
            .padding(20)
        }
    }

    private var goalStep: some View {
        VStack(spacing: 16) {
            stepTitle("Your Quest", subtitle: "What are we training for?")
            ForEach(Goal.allCases) { g in
                Button { goal = g } label: {
                    HStack(spacing: 14) {
                        Image(systemName: g.icon).font(.title2)
                            .foregroundStyle(goal == g ? SystemTheme.accent : SystemTheme.textSecondary)
                            .frame(width: 30)
                        Text(g.label).font(.system(.headline, design: .rounded))
                            .foregroundStyle(SystemTheme.textPrimary)
                        Spacer()
                        if goal == g { Image(systemName: "checkmark.circle.fill").foregroundStyle(SystemTheme.accent) }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(SystemTheme.panel))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(goal == g ? SystemTheme.accent : .clear, lineWidth: 1.5))
                }
            }
            Spacer()
        }
        .padding(20)
    }

    private var summary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                stepTitle("System Calibration", subtitle: "Your daily targets, derived from your data.")
                BodyStatsPanel(profile: profile)
                Text("You can change any of this later in Settings.")
                    .font(.caption).foregroundStyle(SystemTheme.textSecondary)
            }
            .padding(20)
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack {
            if step > 0 {
                Button("Back") { withAnimation { step -= 1 } }
                    .foregroundStyle(SystemTheme.textSecondary)
            }
            Spacer()
            Button {
                if step < 3 { withAnimation { step += 1 } }
                else { Task { await vm.completeOnboarding(name: name, body: profile) } }
            } label: {
                Text(step < 3 ? "Continue" : "AWAKEN")
                    .font(.system(.headline, design: .rounded).weight(.bold)).tracking(1)
                    .padding(.horizontal, 36).padding(.vertical, 12)
                    .background(Capsule().fill(SystemTheme.accentDeep))
                    .overlay(Capsule().stroke(SystemTheme.accent, lineWidth: 1))
                    .foregroundStyle(.white).systemGlow()
            }
        }
    }

    // MARK: Bits

    private var liveBMI: some View {
        HStack {
            Text("BMI").font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundStyle(SystemTheme.textSecondary)
            Spacer()
            Text(String(format: "%.1f", profile.bmi)).font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(SystemTheme.accent)
            Text(profile.bmiCategory.rawValue).font(.caption).foregroundStyle(SystemTheme.textSecondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(SystemTheme.panel))
    }

    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased()).font(.system(.title2, design: .rounded).weight(.heavy)).tracking(1)
                .foregroundStyle(SystemTheme.textPrimary)
            Text(subtitle).font(.system(.subheadline, design: .rounded)).foregroundStyle(SystemTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased()).font(.system(.caption2, design: .monospaced).weight(.bold))
                .foregroundStyle(SystemTheme.textSecondary)
            content()
        }
    }

    private func slider(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        field("\(label) · \(Int(value.wrappedValue)) \(unit)") {
            Slider(value: value, in: range, step: 1).tint(SystemTheme.accent)
        }
    }

    private func seedFromPrefill() {
        guard !didSeed else { return }
        didSeed = true
        let p = vm.bodyPrefill
        if vm.profile.name != "Hunter" { name = vm.profile.name }
        if let s = p.sex { sex = s }
        if let d = p.birthDate { birthDate = d }
        if let h = p.heightCm, h > 0 { heightCm = h }
        if let w = p.weightKg, w > 0 { weightKg = w }
    }
}

private struct ProgressDots: View {
    let count: Int; let index: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? SystemTheme.accent : SystemTheme.textSecondary.opacity(0.3))
                    .frame(width: i == index ? 22 : 8, height: 6)
            }
        }
    }
}
