import SwiftUI

/// The signature translucent blue "System window" with a glowing border and
/// little corner ticks, à la Solo Leveling status panels.
struct SystemPanel<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(SystemTheme.accent)
                        .frame(width: 3, height: 16)
                    Text(title.uppercased())
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .tracking(2)
                        .foregroundStyle(SystemTheme.textPrimary)
                }
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(SystemTheme.panel)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(
                            colors: [SystemTheme.accentDeep.opacity(0.18), .clear],
                            startPoint: .top, endPoint: .bottom))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(SystemTheme.panelStroke.opacity(0.7), lineWidth: 1)
        )
        .overlay(CornerTicks().stroke(SystemTheme.accent, lineWidth: 2))
        .systemGlow(SystemTheme.accent.opacity(0.4), radius: 6)
    }
}

/// Small L-shaped ticks in each corner of a panel.
private struct CornerTicks: Shape {
    let len: CGFloat = 14
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.insetBy(dx: 1, dy: 1)
        // top-left
        p.move(to: CGPoint(x: r.minX, y: r.minY + len)); p.addLine(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.minX + len, y: r.minY))
        // top-right
        p.move(to: CGPoint(x: r.maxX - len, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY + len))
        // bottom-right
        p.move(to: CGPoint(x: r.maxX, y: r.maxY - len)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.maxX - len, y: r.maxY))
        // bottom-left
        p.move(to: CGPoint(x: r.minX + len, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY - len))
        return p
    }
}
