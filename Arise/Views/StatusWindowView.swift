import SwiftUI

/// The hero "STATUS" window: rank, level, name, XP and the five stats.
struct StatusWindowView: View {
    @ObservedObject var vm: SystemViewModel

    var body: some View {
        SystemPanel(title: "Status") {
            VStack(alignment: .leading, spacing: 18) {
                header
                XPBar(into: vm.levelProgress.into, span: vm.levelProgress.span)

                Divider().overlay(SystemTheme.panelStroke.opacity(0.3))

                VStack(spacing: 12) {
                    ForEach(vm.stats) { StatBar(stat: $0) }
                }

                if vm.conditionModifier != 1.0 {
                    conditionRow
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            RankBadge(rank: vm.profile.rank)
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.profile.name)
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(SystemTheme.textPrimary)
                Text(vm.profile.rank.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(vm.profile.rank.color)
            }
            Spacer()
            VStack(spacing: 0) {
                Text("LV")
                    .font(.system(.caption2, design: .monospaced).weight(.bold))
                    .foregroundStyle(SystemTheme.textSecondary)
                Text("\(vm.profile.level)")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(SystemTheme.accent)
                    .systemGlow()
            }
        }
    }

    private var conditionRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "scalemass.fill")
                .foregroundStyle(SystemTheme.gold)
            Text("Body Condition")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(SystemTheme.textSecondary)
            Spacer()
            Text(vm.conditionModifier >= 1 ? "+\(Int((vm.conditionModifier - 1) * 100))% buff"
                                           : "\(Int((vm.conditionModifier - 1) * 100))% debuff")
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundStyle(vm.conditionModifier >= 1 ? SystemTheme.accent : SystemTheme.danger)
        }
        .padding(.top, 2)
    }
}

/// Hexagonal rank emblem with the letter grade.
struct RankBadge: View {
    let rank: Rank

    var body: some View {
        ZStack {
            Hexagon()
                .fill(LinearGradient(colors: [rank.color.opacity(0.35), .black.opacity(0.4)],
                                     startPoint: .top, endPoint: .bottom))
            Hexagon().stroke(rank.color, lineWidth: 2)
            Text(rank == .monarch ? "M" : rank.rawValue)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(rank.color)
                .systemGlow(rank.color, radius: 5)
        }
        .frame(width: 64, height: 70)
    }
}

private struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let pts = [
            CGPoint(x: w * 0.5, y: 0), CGPoint(x: w, y: h * 0.25),
            CGPoint(x: w, y: h * 0.75), CGPoint(x: w * 0.5, y: h),
            CGPoint(x: 0, y: h * 0.75), CGPoint(x: 0, y: h * 0.25),
        ]
        p.addLines(pts)
        p.closeSubpath()
        return p
    }
}
