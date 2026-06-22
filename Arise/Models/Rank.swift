import SwiftUI

/// Hunter rank, derived purely from Level. See SYSTEM_DESIGN.md §3.
enum Rank: String, CaseIterable, Codable, Comparable {
    case e = "E"
    case d = "D"
    case c = "C"
    case b = "B"
    case a = "A"
    case s = "S"
    case monarch = "MONARCH"

    /// Lowest level that belongs to this rank.
    var minLevel: Int {
        switch self {
        case .e: return 1
        case .d: return 10
        case .c: return 25
        case .b: return 45
        case .a: return 70
        case .s: return 100
        case .monarch: return 150
        }
    }

    static func forLevel(_ level: Int) -> Rank {
        allCases.last { level >= $0.minLevel } ?? .e
    }

    var title: String {
        switch self {
        case .e: return "E-Rank Hunter"
        case .d: return "D-Rank Hunter"
        case .c: return "C-Rank Hunter"
        case .b: return "B-Rank Hunter"
        case .a: return "A-Rank Hunter"
        case .s: return "S-Rank Hunter"
        case .monarch: return "Monarch"
        }
    }

    var color: Color {
        switch self {
        case .e: return Color(hex: 0x8FA6C4)
        case .d: return Color(hex: 0x4ED2A0)
        case .c: return Color(hex: 0x35C2FF)
        case .b: return Color(hex: 0x9B6BFF)
        case .a: return Color(hex: 0xFFC857)
        case .s: return Color(hex: 0xFF8A3D)
        case .monarch: return Color(hex: 0xFF4D6D)
        }
    }

    static func < (lhs: Rank, rhs: Rank) -> Bool {
        (allCases.firstIndex(of: lhs) ?? 0) < (allCases.firstIndex(of: rhs) ?? 0)
    }
}
