import SwiftUI

/// Hydration, caffeine and the meal schedule with calorie tracking.
struct FuelView: View {
    @ObservedObject var vm: SystemViewModel
    @State private var addingMeal: MealType?

    private var t: NutritionTargets { vm.targets }
    private var log: DailyLog { vm.todayLog }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                calorieSummary
                hydration
                caffeine
                meals
                Color.clear.frame(height: 20)
            }
            .padding(16)
        }
        .sheet(item: $addingMeal) { type in
            AddMealSheet(type: type) { vm.logMeal($0) }
        }
    }

    // MARK: Calories

    private var calorieSummary: some View {
        SystemPanel(title: "Daily Fuel") {
            let consumed = log.totalCalories
            let remaining = max(0, t.calories - consumed)
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    bigStat("\(consumed)", "eaten")
                    Spacer()
                    bigStat("\(t.calories)", "target")
                    Spacer()
                    bigStat("\(remaining)", "left")
                }
                ProgressBar(fraction: t.calories > 0 ? Double(consumed) / Double(t.calories) : 0,
                            color: consumed > t.calories ? SystemTheme.danger : SystemTheme.gold)
                HStack {
                    Label("\(Int(log.totalProteinG)) / \(t.proteinG) g protein", systemImage: "fork.knife")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(StatKind.strength.color)
                    Spacer()
                }
            }
        }
    }

    // MARK: Hydration

    private var hydration: some View {
        SystemPanel(title: "Hydration") {
            VStack(spacing: 14) {
                HStack {
                    Image(systemName: "drop.fill").foregroundStyle(Color(hex: 0x35C2FF)).font(.title2)
                    Text("\(log.waterMl) mL").font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(SystemTheme.textPrimary)
                    Text("/ \(t.waterMl) mL").font(.subheadline).foregroundStyle(SystemTheme.textSecondary)
                    Spacer()
                }
                ProgressBar(fraction: t.waterMl > 0 ? Double(log.waterMl) / Double(t.waterMl) : 0,
                            color: Color(hex: 0x35C2FF))
                HStack(spacing: 10) {
                    quickAdd("＋ Glass", "250 mL") { vm.addWater(250) }
                    quickAdd("＋ Bottle", "500 mL") { vm.addWater(500) }
                    quickAdd("－", "250 mL") { vm.addWater(-250) }
                }
            }
        }
    }

    // MARK: Caffeine

    private var caffeine: some View {
        SystemPanel(title: "Caffeine") {
            let over = log.caffeineMg > t.caffeineLimitMg
            VStack(spacing: 14) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundStyle(over ? SystemTheme.danger : SystemTheme.gold).font(.title2)
                    Text("\(log.caffeineMg) mg").font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(over ? SystemTheme.danger : SystemTheme.textPrimary)
                    Text("/ \(t.caffeineLimitMg) mg limit").font(.subheadline).foregroundStyle(SystemTheme.textSecondary)
                    Spacer()
                }
                ProgressBar(fraction: t.caffeineLimitMg > 0 ? Double(log.caffeineMg) / Double(t.caffeineLimitMg) : 0,
                            color: over ? SystemTheme.danger : SystemTheme.gold)
                HStack(spacing: 10) {
                    quickAdd("Coffee", "95 mg") { vm.addCaffeine(95) }
                    quickAdd("Espresso", "63 mg") { vm.addCaffeine(63) }
                    quickAdd("Energy", "160 mg") { vm.addCaffeine(160) }
                }
                if over {
                    Text("⚠︎ Over your limit — VIT recovery takes a hit.")
                        .font(.caption).foregroundStyle(SystemTheme.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: Meals

    private var meals: some View {
        SystemPanel(title: "Meal Schedule") {
            VStack(spacing: 12) {
                ForEach(MealType.allCases) { type in
                    MealRow(type: type, entries: log.meals(of: type),
                            onAdd: { addingMeal = type },
                            onRemove: { vm.removeMeal($0) })
                    if type != MealType.allCases.last { Divider().overlay(SystemTheme.panelStroke.opacity(0.2)) }
                }
            }
        }
    }

    // MARK: Bits

    private func bigStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(.title, design: .rounded).weight(.heavy)).foregroundStyle(SystemTheme.textPrimary)
            Text(label).font(.system(.caption2, design: .monospaced)).foregroundStyle(SystemTheme.textSecondary)
        }
    }

    private func quickAdd(_ title: String, _ sub: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(title).font(.system(.subheadline, design: .rounded).weight(.bold))
                Text(sub).font(.system(size: 9, design: .monospaced))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(SystemTheme.accentDeep.opacity(0.4)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(SystemTheme.panelStroke.opacity(0.5), lineWidth: 1))
            .foregroundStyle(SystemTheme.textPrimary)
        }
    }
}

private struct MealRow: View {
    let type: MealType
    let entries: [MealEntry]
    let onAdd: () -> Void
    let onRemove: (UUID) -> Void

    private var kcal: Int { entries.reduce(0) { $0 + $1.calories } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: type.icon).foregroundStyle(SystemTheme.accent).frame(width: 22)
                Text(type.label).font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(SystemTheme.textPrimary)
                Text(String(format: "%02d:00", type.suggestedHour))
                    .font(.system(.caption2, design: .monospaced)).foregroundStyle(SystemTheme.textSecondary)
                Spacer()
                if kcal > 0 {
                    Text("\(kcal) kcal").font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundStyle(SystemTheme.gold)
                }
                Button(action: onAdd) { Image(systemName: "plus.circle.fill").foregroundStyle(SystemTheme.accent) }
            }
            ForEach(entries) { e in
                HStack {
                    Text("• \(e.name)").font(.caption).foregroundStyle(SystemTheme.textSecondary)
                    Spacer()
                    Text("\(e.calories) kcal").font(.system(.caption2, design: .monospaced)).foregroundStyle(SystemTheme.textSecondary)
                    Button { onRemove(e.id) } label: { Image(systemName: "xmark.circle").font(.caption2).foregroundStyle(SystemTheme.textSecondary) }
                }
                .padding(.leading, 30)
            }
        }
    }
}

struct ProgressBar: View {
    let fraction: Double
    let color: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.06))
                Capsule().fill(LinearGradient(colors: [color.opacity(0.6), color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(4, geo.size.width * min(1, max(0, fraction))))
                    .systemGlow(color, radius: 3)
            }
        }
        .frame(height: 8)
    }
}

/// Modal to log a meal: name, calories, optional protein.
private struct AddMealSheet: View {
    let type: MealType
    let onSave: (MealEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(type.label) {
                    TextField("What did you eat?", text: $name)
                    TextField("Calories (kcal)", text: $calories).keyboardType(.numberPad)
                    TextField("Protein (g, optional)", text: $protein).keyboardType(.numberPad)
                }
            }
            .navigationTitle("Log \(type.label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let entry = MealEntry(type: type,
                                              name: name.isEmpty ? type.label : name,
                                              calories: Int(calories) ?? 0,
                                              proteinG: Double(protein))
                        onSave(entry); dismiss()
                    }
                    .disabled((Int(calories) ?? 0) <= 0)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
