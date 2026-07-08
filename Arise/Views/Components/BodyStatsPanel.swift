import SwiftUI

/// Shows derived body metrics and daily targets. How each number is computed:
/// BMI = kg/m² · BMR = Mifflin–St Jeor · TDEE = BMR × activity · targets shift
/// with the chosen goal.
struct BodyStatsPanel: View {
    let profile: BodyProfile

    var body: some View {
        SystemPanel(title: "Vitals & Targets") {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    metric("BMI", String(format: "%.1f", profile.bmi), profile.bmiCategory.rawValue, SystemTheme.accent)
                    metric("BMR", "\(Int(profile.bmr))", "kcal rest", SystemTheme.gold)
                    metric("TDEE", "\(Int(profile.tdee))", "kcal/day", SystemTheme.glow)
                }
                Divider().overlay(SystemTheme.panelStroke.opacity(0.3))
                let t = profile.targets
                target("flame.fill", "Calories", "\(t.calories) kcal", profile.goal.label, SystemTheme.danger)
                target("fork.knife", "Protein", "\(t.proteinG) g", "muscle fuel", StatKind.strength.color)
                target("drop.fill", "Water", "\(t.waterMl) mL", "≈\(t.waterMl / 250) glasses", Color(hex: 0x35C2FF))
                target("cup.and.saucer.fill", "Caffeine limit", "\(t.caffeineLimitMg) mg", "stay under", SystemTheme.textSecondary)
            }
        }
    }

    private func metric(_ label: String, _ value: String, _ sub: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.system(.caption2, design: .monospaced).weight(.bold)).foregroundStyle(SystemTheme.textSecondary)
            Text(value).font(.system(.title2, design: .rounded).weight(.heavy)).foregroundStyle(color)
            Text(sub).font(.system(size: 9)).foregroundStyle(SystemTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
    }

    private func target(_ icon: String, _ label: String, _ value: String, _ sub: String, _ color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 22)
            Text(label).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundStyle(SystemTheme.textPrimary)
            Spacer()
            Text(value).font(.system(.subheadline, design: .monospaced).weight(.bold)).foregroundStyle(color)
            Text(sub).font(.caption2).foregroundStyle(SystemTheme.textSecondary).frame(width: 80, alignment: .trailing)
        }
    }
}
