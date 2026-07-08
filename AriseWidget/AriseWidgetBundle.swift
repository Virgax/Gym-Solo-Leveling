import WidgetKit
import SwiftUI

@main
struct AriseWidgetBundle: WidgetBundle {
    var body: some Widget {
        StatusWidget()
        #if canImport(ActivityKit)
        GateLiveActivityWidget()
        #endif
    }
}

/// Shared palette for the widget target (mirrors the app's System theme).
enum WidgetTheme {
    static let accent = Color(red: 0.208, green: 0.76, blue: 1.0)
    static let accentDeep = Color(red: 0.12, green: 0.42, blue: 1.0)
    static let background = Color(red: 0.02, green: 0.027, blue: 0.059)
    static let textPrimary = Color(red: 0.92, green: 0.96, blue: 1.0)
    static let textSecondary = Color(red: 0.56, green: 0.65, blue: 0.77)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.34)

    static func rankColor(_ raw: String) -> Color {
        switch raw {
        case "E": return Color(red: 0.56, green: 0.65, blue: 0.77)
        case "D": return Color(red: 0.31, green: 0.82, blue: 0.63)
        case "C": return accent
        case "B": return Color(red: 0.61, green: 0.42, blue: 1.0)
        case "A": return gold
        case "S": return Color(red: 1.0, green: 0.54, blue: 0.24)
        default: return Color(red: 1.0, green: 0.30, blue: 0.43)
        }
    }
}
