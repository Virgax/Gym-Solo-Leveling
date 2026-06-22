import SwiftUI

/// Full-screen "ARISE / LEVEL UP" flash when the Hunter crosses a level.
struct LevelUpOverlay: View {
    let level: Int
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            RadialGradient(colors: [SystemTheme.accent.opacity(0.3), .clear],
                           center: .center, startRadius: 1, endRadius: 320)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("ARISE")
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .tracking(8)
                    .foregroundStyle(SystemTheme.accent)
                    .systemGlow(SystemTheme.glow, radius: 14)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)

                Text("LEVEL UP")
                    .font(.system(.headline, design: .monospaced).weight(.bold))
                    .tracking(4)
                    .foregroundStyle(SystemTheme.textSecondary)

                Text("\(level)")
                    .font(.system(size: 96, weight: .black, design: .rounded))
                    .foregroundStyle(SystemTheme.textPrimary)
                    .systemGlow(SystemTheme.accent, radius: 10)
                    .scaleEffect(appeared ? 1 : 0.3)

                Button(action: onDismiss) {
                    Text("CONTINUE")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .tracking(2)
                        .padding(.horizontal, 36).padding(.vertical, 12)
                        .overlay(Capsule().stroke(SystemTheme.accent, lineWidth: 1.5))
                        .foregroundStyle(SystemTheme.accent)
                }
                .padding(.top, 12)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true }
        }
    }
}
