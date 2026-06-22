import SwiftUI

/// One stat row: icon, abbreviation, glowing value and a condition bar.
struct StatBar: View {
    let stat: Stat

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: stat.kind.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(stat.kind.color)
                    .frame(width: 22)
                Text(stat.kind.abbreviation)
                    .font(.system(.subheadline, design: .monospaced).weight(.bold))
                    .foregroundStyle(SystemTheme.textPrimary)
                Spacer()
                Text("\(stat.value)")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(stat.kind.color)
                    .systemGlow(stat.kind.color, radius: 4)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(LinearGradient(colors: [stat.kind.color.opacity(0.6), stat.kind.color],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, geo.size.width * stat.condition))
                        .systemGlow(stat.kind.color, radius: 3)
                }
            }
            .frame(height: 6)
        }
    }
}
