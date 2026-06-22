import SwiftUI

/// Visual language of "the System" — deep void background, cyan-blue glass
/// panels and glowing accents, à la the Solo Leveling status windows.
enum SystemTheme {
    // Backgrounds
    static let background = Color(hex: 0x05070F)
    static let panel = Color(hex: 0x0C1426).opacity(0.85)
    static let panelStroke = Color(hex: 0x2FA8FF)

    // Accents
    static let accent = Color(hex: 0x35C2FF)      // System cyan
    static let accentDeep = Color(hex: 0x1E6BFF)  // deep blue
    static let glow = Color(hex: 0x5BD6FF)
    static let danger = Color(hex: 0xFF4D6D)
    static let gold = Color(hex: 0xFFC857)

    // Text
    static let textPrimary = Color(hex: 0xEAF4FF)
    static let textSecondary = Color(hex: 0x8FA6C4)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.heavy)
    static let monoFont = Font.system(.body, design: .monospaced)
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

extension View {
    /// Glowing cyan halo used across System panels and text.
    func systemGlow(_ color: Color = SystemTheme.glow, radius: CGFloat = 8) -> some View {
        self.shadow(color: color.opacity(0.7), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }
}
