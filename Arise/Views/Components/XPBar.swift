import SwiftUI

struct XPBar: View {
    let into: Int
    let span: Int

    private var fraction: Double { span <= 0 ? 1 : min(1, Double(into) / Double(span)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("EXP")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(SystemTheme.textSecondary)
                Spacer()
                Text("\(into) / \(span)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(SystemTheme.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(LinearGradient(colors: [SystemTheme.accentDeep, SystemTheme.accent],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, geo.size.width * fraction))
                        .systemGlow(SystemTheme.accent, radius: 4)
                }
            }
            .frame(height: 8)
        }
    }
}
